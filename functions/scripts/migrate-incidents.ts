import {randomUUID} from "node:crypto";
import {getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, GeoPoint, getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {
  approximateCoordinate,
  encodeGeohash,
  normalizeLegacyStatus,
} from "../src/domain";

if (getApps().length === 0) initializeApp();
const db = getFirestore();
const bucket = getStorage().bucket();
const apply = process.argv.includes("--apply");
const backupConfirmed = process.argv.includes("--backup-confirmed");

if (apply && !backupConfirmed) {
  throw new Error(
    "Refusing to write without --backup-confirmed. Export Firestore and " +
      "Storage first.",
  );
}

async function migrateMedia(
  incidentId: string,
  uid: string,
  urls: unknown,
): Promise<string[]> {
  if (!apply || !Array.isArray(urls)) return [];
  const paths: string[] = [];
  for (const value of urls.slice(0, 5)) {
    if (typeof value !== "string" || !value.startsWith("https://")) continue;
    const response = await fetch(value);
    if (!response.ok) continue;
    const path = `incident_media/${incidentId}/${uid}/${randomUUID()}.jpg`;
    await bucket.file(path).save(Buffer.from(await response.arrayBuffer()), {
      contentType: response.headers.get("content-type") ?? "image/jpeg",
      resumable: false,
    });
    paths.push(path);
  }
  return paths;
}

const snapshot = await db.collection("incidents").get();
let migrated = 0;
for (const document of snapshot.docs) {
  const value = document.data();
  if (value.schema_version === 2) continue;
  const legacyPosition =
    value.position && typeof value.position === "object" ?
      value.position as Record<string, unknown> :
      {};
  const exact = legacyPosition.geopoint instanceof GeoPoint ?
    legacyPosition.geopoint :
    new GeoPoint(Number(value.latitude ?? 0), Number(value.longitude ?? 0));
  const uid = String(value.user_id ?? "");
  const publicPoint = new GeoPoint(
    approximateCoordinate(exact.latitude),
    approximateCoordinate(exact.longitude),
  );
  const mediaPaths = uid.length > 0 ?
    await migrateMedia(document.id, uid, value.image_urls) :
    [];
  const description = typeof value.description === "string" ?
    value.description :
    JSON.stringify(value.description ?? {});

  if (apply) {
    const batch = db.batch();
    batch.set(document.ref, {
      schema_version: 2,
      status: normalizeLegacyStatus(value.status),
      title: String(value.title ?? "Emergency report").slice(0, 120),
      incident_type: String(value.incident_type ?? "other").slice(0, 40),
      urgency: String(value.urgency ?? "unknown").slice(0, 30),
      public_summary: "",
      position: {
        geohash: encodeGeohash(exact.latitude, exact.longitude, 6),
        geopoint: publicPoint,
      },
      follower_count: Array.isArray(value.followers) ?
        value.followers.length :
        0,
      enrichment_complete: true,
      updated_at: FieldValue.serverTimestamp(),
      // Remove fields that exposed private information in the legacy schema.
      user_id: FieldValue.delete(),
      reporter_name: FieldValue.delete(),
      reporter_tel: FieldValue.delete(),
      description: FieldValue.delete(),
      image_urls: FieldValue.delete(),
      followers: FieldValue.delete(),
      latitude: FieldValue.delete(),
      longitude: FieldValue.delete(),
    }, {merge: true});
    batch.set(db.collection("incident_private").doc(document.id), {
      schema_version: 2,
      reporter_uid: uid || null,
      reporter_name: value.reporter_name ?? null,
      reporter_phone: value.reporter_tel ?? null,
      exact_position: exact,
      accuracy_m: null,
      last_known_position: null,
      medical_summary_consent: false,
      private_details: {legacy_description: description},
      media_paths: mediaPaths,
      created_at: value.created_at ?? FieldValue.serverTimestamp(),
      retention_due_at: value.created_at?.toDate ?
        new Date(value.created_at.toDate().getTime() + 90 * 86400000) :
        new Date(Date.now() + 90 * 86400000),
      anonymized_at: null,
    }, {merge: true});
    await batch.commit();
  }
  migrated += 1;
}

console.log(`${apply ? "Migrated" : "Would migrate"} ${migrated} incidents.`);
