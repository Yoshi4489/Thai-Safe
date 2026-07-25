import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {db, storage} from "./firebase";
import {writeAudit} from "./audit";

export const anonymizeExpiredIncidents = onSchedule({
  region: "asia-southeast1",
  schedule: "every day 03:15",
  timeZone: "Asia/Bangkok",
  retryCount: 3,
}, async () => {
  const expired = await db.collection("incident_private")
    .where("retention_due_at", "<=", Timestamp.now())
    .where("anonymized_at", "==", null)
    .limit(100)
    .get();

  for (const privateIncident of expired.docs) {
    const data = privateIncident.data();
    const mediaPaths = Array.isArray(data.media_paths) ?
      data.media_paths.filter((path): path is string =>
        typeof path === "string") :
      [];
    await Promise.all(mediaPaths.map((path) =>
      storage.bucket().file(path).delete({ignoreNotFound: true})));

    const batch = db.batch();
    batch.update(privateIncident.ref, {
      reporter_uid: null,
      reporter_name: null,
      reporter_phone: null,
      exact_position: null,
      last_known_position: null,
      private_details: {},
      media_paths: [],
      medical_summary_consent: false,
      anonymized_at: FieldValue.serverTimestamp(),
    });
    batch.set(db.collection("incident_assignments").doc(privateIncident.id), {
      reporter_uid: null,
      anonymized_at: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();
    await writeAudit(
      "system",
      "incident.anonymize",
      "incident",
      privateIncident.id,
    );
  }
});
