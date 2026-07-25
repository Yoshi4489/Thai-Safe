import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore} from "firebase-admin/firestore";

if (getApps().length === 0) initializeApp();
const apply = process.argv.includes("--apply");
const db = getFirestore();
const auth = getAuth();
const users = await db.collection("users").get();
let changed = 0;

for (const document of users.docs) {
  const legacy = String(document.get("role") ?? "user").toLowerCase();
  const role = legacy === "admin" ? "admin" :
    ["rescue", "rescuer", "responder", "officer"].includes(legacy) ?
      "responder" :
      "user";
  if (legacy === role && !apply) continue;
  if (apply) {
    const record = await auth.getUser(document.id);
    await auth.setCustomUserClaims(document.id, {
      ...(record.customClaims ?? {}),
      role,
      responderApproved: role === "responder",
    });
    await document.ref.set({role}, {merge: true});
  }
  changed += 1;
}

console.log(`${apply ? "Backfilled" : "Would backfill"} ${changed} roles.`);
