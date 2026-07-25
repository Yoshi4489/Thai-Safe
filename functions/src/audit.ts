import {FieldValue} from "firebase-admin/firestore";
import {db} from "./firebase";

export async function writeAudit(
  actorUid: string,
  action: string,
  targetType: string,
  targetId: string,
  metadata: Record<string, unknown> = {},
): Promise<void> {
  await db.collection("audit_logs").add({
    actor_uid: actorUid,
    action,
    target_type: targetType,
    target_id: targetId,
    metadata,
    created_at: FieldValue.serverTimestamp(),
  });
}
