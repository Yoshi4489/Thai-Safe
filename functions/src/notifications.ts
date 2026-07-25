import {FieldValue} from "firebase-admin/firestore";
import {db, messaging} from "./firebase";

export async function notifyUser(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<void> {
  const notificationRef = db
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc();

  await notificationRef.set({
    title,
    body,
    data,
    created_at: FieldValue.serverTimestamp(),
    read_at: null,
  });

  const devices = await db
    .collection("users")
    .doc(uid)
    .collection("devices")
    .where("enabled", "==", true)
    .get();
  const tokens = devices.docs
    .map((doc) => doc.get("token"))
    .filter((token): token is string => typeof token === "string");
  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens: tokens.slice(0, 500),
    notification: {title, body},
    data,
    android: {
      priority: "high",
      notification: {channelId: "thai_safe_incidents"},
    },
  });
}
