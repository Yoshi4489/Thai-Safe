import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {writeAudit} from "./audit";
import {cleanText, isSafeStoragePath} from "./domain";
import {auth, db} from "./firebase";
import {notifyUser} from "./notifications";
import {requireRole, requireUid} from "./security";

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

export const applyAsResponder = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const organization = cleanText(data.organization, 160);
  const identityNumberLast4 = cleanText(data.identityNumberLast4, 4);
  const evidencePaths = Array.isArray(data.evidencePaths) ?
    data.evidencePaths.map((value) => cleanText(value, 512)) :
    [];

  if (organization.length < 2 ||
      !/^[0-9A-Za-z]{4}$/.test(identityNumberLast4) ||
      evidencePaths.length === 0 ||
      evidencePaths.length > 5 ||
      evidencePaths.some((path) =>
        !isSafeStoragePath(path, "responder_evidence", uid))) {
    throw new HttpsError(
      "invalid-argument",
      "Organization, last four ID characters, and evidence are required.",
    );
  }

  const ref = db.collection("responder_applications").doc(uid);
  const existing = await ref.get();
  if (existing.exists &&
      ["pending", "approved"].includes(existing.get("status"))) {
    throw new HttpsError(
      "failed-precondition",
      "An active responder application already exists.",
    );
  }

  await ref.set({
    uid,
    organization,
    identity_number_last4: identityNumberLast4,
    evidence_paths: evidencePaths,
    status: "pending",
    submitted_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
    reviewed_at: null,
    reviewed_by: null,
    expires_at: null,
    decision_reason: null,
  });
  await writeAudit(
    uid,
    "responder.application_submit",
    "responder_application",
    uid,
  );
  return {status: "pending"};
});

export const reviewResponderApplication = onCall(
  callable,
  async (request) => {
    const adminUid = requireUid(request);
    requireRole(request, ["admin"]);
    const data = objectData(request.data);
    const applicantUid = cleanText(data.uid, 128);
    const action = cleanText(data.action, 20).toLowerCase();
    const reason = cleanText(data.reason, 500);
    const validActions = ["approve", "reject", "expire", "suspend", "revoke"];
    if (!/^[A-Za-z0-9:_-]{8,128}$/.test(applicantUid) ||
        !validActions.includes(action) ||
        (action !== "approve" && reason.length < 5)) {
      throw new HttpsError("invalid-argument", "Invalid review decision.");
    }

    const applicationRef = db
      .collection("responder_applications")
      .doc(applicantUid);
    const application = await applicationRef.get();
    if (!application.exists) {
      throw new HttpsError("not-found", "Responder application not found.");
    }

    const status = action === "approve" ? "approved" :
      action === "reject" ? "rejected" :
        action === "expire" ? "expired" : action;
    const userRecord = await auth.getUser(applicantUid);
    const existingClaims = userRecord.customClaims ?? {};
    const role = action === "approve" ? "responder" : "user";
    await auth.setCustomUserClaims(applicantUid, {
      ...existingClaims,
      role,
      responderApproved: action === "approve",
    });

    const expiresAt = action === "approve" ?
      Timestamp.fromMillis(Date.now() + 365 * 24 * 60 * 60 * 1000) :
      null;
    const batch = db.batch();
    batch.update(applicationRef, {
      status,
      decision_reason: reason.length > 0 ? reason : null,
      reviewed_at: FieldValue.serverTimestamp(),
      reviewed_by: adminUid,
      updated_at: FieldValue.serverTimestamp(),
      expires_at: expiresAt,
    });
    batch.set(db.collection("users").doc(applicantUid), {
      role,
      role_updated_at: FieldValue.serverTimestamp(),
    }, {merge: true});
    await batch.commit();

    await notifyUser(
      applicantUid,
      "Responder application updated",
      action === "approve" ?
        "Your volunteer responder application was approved." :
        `Your responder status is now ${status}.`,
      {type: "responder_application", status},
    );
    await writeAudit(
      adminUid,
      `responder.${action}`,
      "responder_application",
      applicantUid,
      {reason},
    );
    return {uid: applicantUid, status, refreshToken: true};
  },
);
