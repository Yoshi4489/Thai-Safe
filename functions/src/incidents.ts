import {GeoPoint, Timestamp, FieldValue} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {
  approximateCoordinate,
  canTransition,
  cleanText,
  encodeGeohash,
  isIncidentStatus,
  isSafeStoragePath,
  validCoordinates,
} from "./domain";
import {db, storage} from "./firebase";
import {notifyUser} from "./notifications";
import {requireRole, requireUid, roleOf} from "./security";
import {writeAudit} from "./audit";

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

function incidentIdFrom(data: Record<string, unknown>): string {
  const id = cleanText(data.incidentId, 128);
  if (!/^[A-Za-z0-9_-]{8,128}$/.test(id)) {
    throw new HttpsError("invalid-argument", "Invalid incident ID.");
  }
  return id;
}

export const submitQuickIncident = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const clientRequestId = cleanText(data.clientRequestId, 128);
  const latitude = Number(data.latitude);
  const longitude = Number(data.longitude);
  const accuracyM = Number(data.accuracyM);

  if (!/^[A-Za-z0-9_-]{8,128}$/.test(clientRequestId)) {
    throw new HttpsError("invalid-argument", "Invalid client request ID.");
  }
  if (!validCoordinates(latitude, longitude)) {
    throw new HttpsError("invalid-argument", "Invalid GPS coordinates.");
  }
  if (!Number.isFinite(accuracyM) || accuracyM < 0 || accuracyM > 100000) {
    throw new HttpsError("invalid-argument", "Invalid GPS accuracy.");
  }

  const requestRef = db
    .collection("incident_requests")
    .doc(`${uid}_${clientRequestId}`);
  const rateRef = db.collection("rate_limits").doc(`incident_${uid}`);
  const incidentRef = db.collection("incidents").doc();
  const privateRef = db.collection("incident_private").doc(incidentRef.id);
  const userRef = db.collection("users").doc(uid);
  const now = Timestamp.now();

  const result = await db.runTransaction(async (transaction) => {
    const duplicate = await transaction.get(requestRef);
    if (duplicate.exists) {
      return {
        incidentId: String(duplicate.get("incident_id")),
        duplicate: true,
      };
    }

    const [rateSnapshot, userSnapshot] = await Promise.all([
      transaction.get(rateRef),
      transaction.get(userRef),
    ]);
    const windowStart = rateSnapshot.get("window_start") as Timestamp | null;
    const inWindow = windowStart != null &&
      now.toMillis() - windowStart.toMillis() < 10 * 60 * 1000;
    const count = inWindow ? Number(rateSnapshot.get("count") ?? 0) : 0;
    if (count >= 5) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many reports. Call emergency services if danger is immediate.",
      );
    }

    const publicLatitude = approximateCoordinate(latitude);
    const publicLongitude = approximateCoordinate(longitude);
    const publicGeohash = encodeGeohash(latitude, longitude, 6);
    const lastKnown = objectData(data.lastKnown ?? {});
    const lastKnownLatitude = Number(lastKnown.latitude);
    const lastKnownLongitude = Number(lastKnown.longitude);
    const hasLastKnown = validCoordinates(
      lastKnownLatitude,
      lastKnownLongitude,
    );

    transaction.set(incidentRef, {
      schema_version: 2,
      status: "pending",
      title: "Emergency report",
      incident_type: "unclassified",
      urgency: "unknown",
      position: {
        geohash: publicGeohash,
        geopoint: new GeoPoint(publicLatitude, publicLongitude),
      },
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      follower_count: 1,
      enrichment_complete: false,
    });
    transaction.set(privateRef, {
      schema_version: 2,
      reporter_uid: uid,
      reporter_name: cleanText(
        `${userSnapshot.get("first_name") ?? ""} ` +
          `${userSnapshot.get("last_name") ?? ""}`,
        160,
      ),
      reporter_phone: cleanText(userSnapshot.get("tel"), 40),
      exact_position: new GeoPoint(latitude, longitude),
      accuracy_m: accuracyM,
      last_known_position: hasLastKnown ?
        new GeoPoint(lastKnownLatitude, lastKnownLongitude) :
        null,
      medical_summary_consent: data.medicalSummaryConsent === true,
      private_details: {},
      media_paths: [],
      created_at: FieldValue.serverTimestamp(),
      retention_due_at: Timestamp.fromMillis(
        now.toMillis() + 90 * 24 * 60 * 60 * 1000,
      ),
    });
    transaction.set(requestRef, {
      uid,
      client_request_id: clientRequestId,
      incident_id: incidentRef.id,
      created_at: FieldValue.serverTimestamp(),
    });
    transaction.set(rateRef, {
      count: count + 1,
      window_start: inWindow ? windowStart : now,
      updated_at: FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection("incident_followers").doc(`${incidentRef.id}_${uid}`),
      {
        incident_id: incidentRef.id,
        uid,
        created_at: FieldValue.serverTimestamp(),
      },
    );
    return {incidentId: incidentRef.id, duplicate: false};
  });

  await writeAudit(uid, "incident.quick_submit", "incident", result.incidentId, {
    duplicate: result.duplicate,
  });
  return result;
});

export const enrichIncident = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const incidentId = incidentIdFrom(data);
  const category = cleanText(data.category, 40, "other").toLowerCase();
  const urgency = cleanText(data.urgency, 30, "unknown").toLowerCase();
  const title = cleanText(data.title, 120, "Emergency report");
  const summary = cleanText(data.summary, 500);
  const privateDetails = objectData(data.details ?? {});
  const mediaPaths = Array.isArray(data.mediaPaths) ?
    data.mediaPaths.map((value) => cleanText(value, 512)) :
    [];

  if (mediaPaths.length > 5 ||
      mediaPaths.some((path) =>
        !isSafeStoragePath(path, `incident_media/${incidentId}`, uid))) {
    throw new HttpsError("invalid-argument", "Invalid incident media path.");
  }

  const publicRef = db.collection("incidents").doc(incidentId);
  const privateRef = db.collection("incident_private").doc(incidentId);
  await db.runTransaction(async (transaction) => {
    const [publicSnapshot, privateSnapshot] = await Promise.all([
      transaction.get(publicRef),
      transaction.get(privateRef),
    ]);
    if (!publicSnapshot.exists || !privateSnapshot.exists) {
      throw new HttpsError("not-found", "Incident not found.");
    }
    if (privateSnapshot.get("reporter_uid") !== uid) {
      throw new HttpsError("permission-denied", "Only the reporter can edit.");
    }
    if (["resolved", "cancelled"].includes(publicSnapshot.get("status"))) {
      throw new HttpsError("failed-precondition", "Incident is closed.");
    }
    transaction.update(publicRef, {
      title,
      incident_type: category,
      urgency,
      public_summary: summary,
      enrichment_complete: true,
      updated_at: FieldValue.serverTimestamp(),
    });
    transaction.update(privateRef, {
      private_details: privateDetails,
      media_paths: mediaPaths,
      updated_at: FieldValue.serverTimestamp(),
    });
  });
  await writeAudit(uid, "incident.enrich", "incident", incidentId);
  return {incidentId};
});

export const acceptIncident = onCall(callable, async (request) => {
  const uid = requireUid(request);
  requireRole(request, ["responder", "admin"]);
  const data = objectData(request.data);
  const incidentId = incidentIdFrom(data);
  const incidentRef = db.collection("incidents").doc(incidentId);
  const privateRef = db.collection("incident_private").doc(incidentId);
  const assignmentRef = db
    .collection("incident_assignments")
    .doc(incidentId);
  const applicationRef = db
    .collection("responder_applications")
    .doc(uid);

  await db.runTransaction(async (transaction) => {
    const [incident, privateIncident, assignment, application] =
      await Promise.all([
        transaction.get(incidentRef),
        transaction.get(privateRef),
        transaction.get(assignmentRef),
        transaction.get(applicationRef),
      ]);
    if (!incident.exists || !privateIncident.exists) {
      throw new HttpsError("not-found", "Incident not found.");
    }
    if (assignment.exists || incident.get("status") !== "pending") {
      throw new HttpsError(
        "already-exists",
        "This incident is already assigned.",
      );
    }
    if (roleOf(request) !== "admin" &&
      (!application.exists || application.get("status") !== "approved")) {
      throw new HttpsError(
        "permission-denied",
        "Responder approval is not active.",
      );
    }

    transaction.update(incidentRef, {
      status: "assigned",
      updated_at: FieldValue.serverTimestamp(),
    });
    transaction.set(assignmentRef, {
      incident_id: incidentId,
      reporter_uid: privateIncident.get("reporter_uid"),
      lead_responder_uid: uid,
      assigned_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
      status: "assigned",
      status_history: [{
        from: "pending",
        to: "assigned",
        actor_uid: uid,
        at: Timestamp.now(),
      }],
      operational_notes: [],
    });
  });

  const privateSnapshot = await privateRef.get();
  const reporterUid = privateSnapshot.get("reporter_uid");
  if (typeof reporterUid === "string") {
    await notifyUser(
      reporterUid,
      "Responder assigned",
      "A verified volunteer responder accepted your report.",
      {incidentId, type: "incident_assigned"},
    );
  }
  await writeAudit(uid, "incident.accept", "incident", incidentId);
  return {incidentId, status: "assigned"};
});

export const transitionIncidentStatus = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const incidentId = incidentIdFrom(data);
  const to = data.status;
  if (!isIncidentStatus(to)) {
    throw new HttpsError("invalid-argument", "Invalid incident status.");
  }
  const note = cleanText(data.note, 1000);
  const incidentRef = db.collection("incidents").doc(incidentId);
  const privateRef = db.collection("incident_private").doc(incidentId);
  const assignmentRef = db
    .collection("incident_assignments")
    .doc(incidentId);

  const reporterUid = await db.runTransaction(async (transaction) => {
    const [incident, privateIncident, assignment] = await Promise.all([
      transaction.get(incidentRef),
      transaction.get(privateRef),
      transaction.get(assignmentRef),
    ]);
    if (!incident.exists || !privateIncident.exists) {
      throw new HttpsError("not-found", "Incident not found.");
    }
    const from = incident.get("status");
    if (!isIncidentStatus(from) || !canTransition(from, to)) {
      throw new HttpsError(
        "failed-precondition",
        `Cannot transition from ${String(from)} to ${to}.`,
      );
    }
    const reporter = privateIncident.get("reporter_uid");
    const isReporter = reporter === uid;
    const isAssigned = assignment.exists &&
      assignment.get("lead_responder_uid") === uid;
    const isAdmin = roleOf(request) === "admin";
    const reporterCancellation = isReporter &&
      to === "cancelled" &&
      (from === "pending" || from === "assigned");
    if (!isAdmin && !isAssigned && !reporterCancellation) {
      throw new HttpsError("permission-denied", "Not assigned to incident.");
    }

    transaction.update(incidentRef, {
      status: to,
      updated_at: FieldValue.serverTimestamp(),
      closed_at: ["resolved", "cancelled"].includes(to) ?
        FieldValue.serverTimestamp() :
        null,
    });
    if (assignment.exists) {
      transaction.update(assignmentRef, {
        status: to,
        updated_at: FieldValue.serverTimestamp(),
        status_history: FieldValue.arrayUnion({
          from,
          to,
          actor_uid: uid,
          at: Timestamp.now(),
        }),
        operational_notes: note.length > 0 ?
          FieldValue.arrayUnion({
            text: note,
            actor_uid: uid,
            at: Timestamp.now(),
          }) :
          assignment.get("operational_notes") ?? [],
      });
    }
    return String(reporter);
  });

  if (reporterUid !== uid) {
    await notifyUser(
      reporterUid,
      "Incident status updated",
      `Your report is now ${to.replaceAll("_", " ")}.`,
      {incidentId, status: to, type: "incident_status"},
    );
  }
  await writeAudit(uid, "incident.transition", "incident", incidentId, {to});
  return {incidentId, status: to};
});

export const getAssignedIncidentPrivate = onCall(
  callable,
  async (request) => {
    const uid = requireUid(request);
    const data = objectData(request.data);
    const incidentId = incidentIdFrom(data);
    const assignment = await db
      .collection("incident_assignments")
      .doc(incidentId)
      .get();
    const isAdmin = roleOf(request) === "admin";
    if (!assignment.exists ||
      (!isAdmin && assignment.get("lead_responder_uid") !== uid) ||
      ["resolved", "cancelled"].includes(assignment.get("status"))) {
      throw new HttpsError(
        "permission-denied",
        "Private data requires an active assignment.",
      );
    }

    const privateIncident = await db
      .collection("incident_private")
      .doc(incidentId)
      .get();
    if (!privateIncident.exists) {
      throw new HttpsError("not-found", "Private incident data not found.");
    }

    const value = privateIncident.data() ?? {};
    const paths = Array.isArray(value.media_paths) ?
      value.media_paths.filter((path): path is string =>
        typeof path === "string") :
      [];
    const expires = Date.now() + 10 * 60 * 1000;
    const mediaUrls = await Promise.all(paths.map(async (path) => {
      const [url] = await storage.bucket().file(path).getSignedUrl({
        action: "read",
        expires,
      });
      return url;
    }));

    await writeAudit(
      uid,
      "incident.private_read",
      "incident",
      incidentId,
    );
    return {
      reporterUid: value.reporter_uid,
      reporterName: value.reporter_name,
      reporterPhone: value.reporter_phone,
      exactPosition: value.exact_position,
      accuracyM: value.accuracy_m,
      details: value.private_details ?? {},
      mediaUrls,
    };
  },
);

export const getEmergencyMedicalSummary = onCall(
  callable,
  async (request) => {
    const uid = requireUid(request);
    requireRole(request, ["responder", "admin"]);
    const data = objectData(request.data);
    const incidentId = incidentIdFrom(data);
    const [assignment, privateIncident] = await Promise.all([
      db.collection("incident_assignments").doc(incidentId).get(),
      db.collection("incident_private").doc(incidentId).get(),
    ]);
    if (!assignment.exists || !privateIncident.exists ||
      (roleOf(request) !== "admin" &&
        assignment.get("lead_responder_uid") !== uid) ||
      ["resolved", "cancelled"].includes(assignment.get("status")) ||
      privateIncident.get("medical_summary_consent") !== true) {
      throw new HttpsError(
        "permission-denied",
        "Medical summary access is not permitted.",
      );
    }
    const reporterUid = privateIncident.get("reporter_uid");
    const profile = await db.collection("medical_profiles")
      .doc(String(reporterUid)).get();
    const value = profile.data() ?? {};
    await writeAudit(
      uid,
      "incident.medical_summary_read",
      "incident",
      incidentId,
    );
    return {
      bloodType: value.blood_type ?? null,
      allergies: value.allergies ?? [],
      conditions: value.chronic_diseases ?? value.conditions ?? [],
      medications: value.medications ?? [],
      emergencyContacts: value.emergency_contacts ?? [],
    };
  },
);

export const followIncident = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const incidentId = incidentIdFrom(data);
  const follow = data.follow !== false;
  const incidentRef = db.collection("incidents").doc(incidentId);
  const followRef = db
    .collection("incident_followers")
    .doc(`${incidentId}_${uid}`);
  await db.runTransaction(async (transaction) => {
    const [incident, existing] = await Promise.all([
      transaction.get(incidentRef),
      transaction.get(followRef),
    ]);
    if (!incident.exists) {
      throw new HttpsError("not-found", "Incident not found.");
    }
    if (follow && !existing.exists) {
      transaction.set(followRef, {
        incident_id: incidentId,
        uid,
        created_at: FieldValue.serverTimestamp(),
      });
      transaction.update(incidentRef, {
        follower_count: FieldValue.increment(1),
      });
    } else if (!follow && existing.exists) {
      transaction.delete(followRef);
      transaction.update(incidentRef, {
        follower_count: FieldValue.increment(-1),
      });
    }
  });
  return {incidentId, following: follow};
});

export const reportIncidentAbuse = onCall(callable, async (request) => {
  const uid = requireUid(request);
  const data = objectData(request.data);
  const incidentId = incidentIdFrom(data);
  const reason = cleanText(data.reason, 500);
  if (reason.length < 10) {
    throw new HttpsError(
      "invalid-argument",
      "Please provide a meaningful reason.",
    );
  }
  const incident = await db.collection("incidents").doc(incidentId).get();
  if (!incident.exists) {
    throw new HttpsError("not-found", "Incident not found.");
  }
  const reportRef = db
    .collection("incident_abuse_reports")
    .doc(`${incidentId}_${uid}`);
  await reportRef.set({
    incident_id: incidentId,
    reporter_uid: uid,
    reason,
    status: "open",
    created_at: FieldValue.serverTimestamp(),
  }, {merge: true});
  await writeAudit(uid, "incident.abuse_report", "incident", incidentId);
  return {reportId: reportRef.id};
});
