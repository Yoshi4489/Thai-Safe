import {FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {writeAudit} from "./audit";
import {cleanText} from "./domain";
import {auth, db} from "./firebase";
import {requireUid} from "./security";

const callable = {
  region: "asia-southeast1",
  enforceAppCheck: true,
  cors: true,
} as const;

function objectData(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "A data object is required.");
  }
  return value as Record<string, unknown>;
}

export const registerDevice = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const deviceId = cleanText(data.deviceId, 160);
  const token = cleanText(data.token, 4096);
  const platform = cleanText(data.platform, 20);
  if (!/^[A-Za-z0-9:_-]{8,160}$/.test(deviceId) ||
      token.length < 20 ||
      !["android", "ios"].includes(platform)) {
    throw new HttpsError("invalid-argument", "Invalid device registration.");
  }
  await db.collection("users").doc(uid).collection("devices").doc(deviceId)
    .set({
      token,
      platform,
      enabled: data.enabled !== false,
      locale: cleanText(data.locale, 20, "th"),
      updated_at: FieldValue.serverTimestamp(),
    }, {merge: true});
  return {registered: true};
});

export const exportMyData = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const [user, medical, privateIncidents, notifications] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("medical_profiles").doc(uid).get(),
    db.collection("incident_private")
      .where("reporter_uid", "==", uid)
      .limit(200)
      .get(),
    db.collection("users").doc(uid).collection("notifications")
      .orderBy("created_at", "desc")
      .limit(200)
      .get(),
  ]);
  const publicIncidents = await Promise.all(
    privateIncidents.docs.map((doc) =>
      db.collection("incidents").doc(doc.id).get()),
  );
  await writeAudit(uid, "account.export", "user", uid);
  return {
    exportedAt: new Date().toISOString(),
    user: user.data() ?? null,
    medicalProfile: medical.data() ?? null,
    incidents: privateIncidents.docs.map((privateDoc, index) => ({
      id: privateDoc.id,
      public: publicIncidents[index].data() ?? null,
      private: privateDoc.data(),
    })),
    notifications: notifications.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })),
  };
});

export const deleteMyAccount = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  if (data.confirmation !== "DELETE") {
    throw new HttpsError(
      "failed-precondition",
      "Type DELETE to confirm account deletion.",
    );
  }

  const privateIncidents = await db.collection("incident_private")
    .where("reporter_uid", "==", uid)
    .limit(400)
    .get();
  const batch = db.batch();
  for (const incident of privateIncidents.docs) {
    batch.update(incident.ref, {
      reporter_uid: null,
      reporter_name: null,
      reporter_phone: null,
      account_deleted_at: FieldValue.serverTimestamp(),
    });
    batch.set(db.collection("incidents").doc(incident.id), {
      reporter_deleted: true,
      updated_at: FieldValue.serverTimestamp(),
    }, {merge: true});
  }
  batch.delete(db.collection("medical_profiles").doc(uid));
  batch.set(db.collection("users").doc(uid), {
    id: uid,
    deleted: true,
    first_name: "Deleted",
    last_name: "User",
    tel: null,
    profile_url: null,
    role: "user",
    deleted_at: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await writeAudit(uid, "account.delete", "user", uid);
  await auth.deleteUser(uid);
  return {deleted: true};
});
