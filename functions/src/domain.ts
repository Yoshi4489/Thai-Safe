export const INCIDENT_STATUSES = [
  "pending",
  "assigned",
  "in_progress",
  "resolved",
  "cancelled",
] as const;

export type IncidentStatus = (typeof INCIDENT_STATUSES)[number];

const transitions: Record<IncidentStatus, ReadonlySet<IncidentStatus>> = {
  pending: new Set(["assigned", "cancelled"]),
  assigned: new Set(["in_progress", "cancelled"]),
  in_progress: new Set(["resolved", "cancelled"]),
  resolved: new Set(),
  cancelled: new Set(),
};

export function isIncidentStatus(value: unknown): value is IncidentStatus {
  return typeof value === "string" &&
    INCIDENT_STATUSES.includes(value as IncidentStatus);
}

export function canTransition(
  from: IncidentStatus,
  to: IncidentStatus,
): boolean {
  return transitions[from].has(to);
}

export function normalizeLegacyStatus(value: unknown): IncidentStatus {
  const normalized = String(value ?? "")
    .trim()
    .toLowerCase()
    .replaceAll(" ", "_");
  switch (normalized) {
  case "acknowledged":
  case "accepted":
    return "assigned";
  case "inprogress":
    return "in_progress";
  case "complete":
  case "completed":
    return "resolved";
  case "canceled":
    return "cancelled";
  default:
    return isIncidentStatus(normalized) ? normalized : "pending";
  }
}

export function approximateCoordinate(value: number): number {
  return Math.round(value * 100) / 100;
}

export function validCoordinates(latitude: number, longitude: number): boolean {
  return Number.isFinite(latitude) &&
    Number.isFinite(longitude) &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;
}

// Standard base-32 geohash implementation. Public incidents retain only six
// characters (roughly neighbourhood-level precision).
export function encodeGeohash(
  latitude: number,
  longitude: number,
  precision = 6,
): string {
  const alphabet = "0123456789bcdefghjkmnpqrstuvwxyz";
  const latitudeRange: [number, number] = [-90, 90];
  const longitudeRange: [number, number] = [-180, 180];
  let hash = "";
  let bits = 0;
  let value = 0;
  let evenBit = true;

  while (hash.length < precision) {
    const range = evenBit ? longitudeRange : latitudeRange;
    const coordinate = evenBit ? longitude : latitude;
    const midpoint = (range[0] + range[1]) / 2;
    if (coordinate >= midpoint) {
      value = value * 2 + 1;
      range[0] = midpoint;
    } else {
      value *= 2;
      range[1] = midpoint;
    }
    evenBit = !evenBit;
    bits += 1;
    if (bits === 5) {
      hash += alphabet[value];
      bits = 0;
      value = 0;
    }
  }
  return hash;
}

export function cleanText(
  value: unknown,
  maxLength: number,
  fallback = "",
): string {
  if (typeof value !== "string") return fallback;
  return value.trim().slice(0, maxLength);
}

export function isSafeStoragePath(
  path: string,
  root: string,
  ownerUid: string,
): boolean {
  return path.startsWith(`${root}/${ownerUid}/`) &&
    !path.includes("..") &&
    path.length <= 512;
}
