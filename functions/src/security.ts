import {CallableRequest, HttpsError} from "firebase-functions/v2/https";

export type AppRole = "user" | "responder" | "admin";

export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  return uid;
}

export function roleOf(request: CallableRequest): AppRole {
  const value = request.auth?.token.role;
  return value === "admin" || value === "responder" ? value : "user";
}

export function requireRole(
  request: CallableRequest,
  roles: readonly AppRole[],
): AppRole {
  requireUid(request);
  const role = roleOf(request);
  if (!roles.includes(role)) {
    throw new HttpsError(
      "permission-denied",
      "This action is not allowed for your account.",
    );
  }
  return role;
}
