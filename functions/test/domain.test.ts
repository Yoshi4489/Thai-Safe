import {describe, expect, it} from "vitest";
import {
  approximateCoordinate,
  canTransition,
  encodeGeohash,
  normalizeLegacyStatus,
  validCoordinates,
} from "../src/domain";

describe("incident domain", () => {
  it("allows only normalized forward transitions", () => {
    expect(canTransition("pending", "assigned")).toBe(true);
    expect(canTransition("assigned", "in_progress")).toBe(true);
    expect(canTransition("in_progress", "resolved")).toBe(true);
    expect(canTransition("resolved", "pending")).toBe(false);
    expect(canTransition("pending", "resolved")).toBe(false);
  });

  it("maps legacy status values during rollout", () => {
    expect(normalizeLegacyStatus("Acknowledged")).toBe("assigned");
    expect(normalizeLegacyStatus("In Progress")).toBe("in_progress");
    expect(normalizeLegacyStatus("Completed")).toBe("resolved");
    expect(normalizeLegacyStatus("unexpected")).toBe("pending");
  });

  it("publishes only reduced location precision", () => {
    expect(approximateCoordinate(13.756331)).toBe(13.76);
    expect(approximateCoordinate(100.501762)).toBe(100.5);
    expect(encodeGeohash(13.756331, 100.501762, 6)).toHaveLength(6);
  });

  it("rejects invalid coordinates", () => {
    expect(validCoordinates(13.75, 100.5)).toBe(true);
    expect(validCoordinates(91, 100.5)).toBe(false);
    expect(validCoordinates(13.75, 181)).toBe(false);
    expect(validCoordinates(Number.NaN, 0)).toBe(false);
  });
});
