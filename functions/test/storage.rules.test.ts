import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {afterAll, beforeAll, describe, it} from "vitest";

const emulatorAvailable = Boolean(
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ||
    process.env.STORAGE_EMULATOR_HOST,
);
const describeWithEmulator = emulatorAvailable ? describe : describe.skip;

describeWithEmulator("Storage security rules", () => {
  let environment: RulesTestEnvironment;

  beforeAll(async () => {
    environment = await initializeTestEnvironment({
      projectId: "thai-safe-storage-rules-test",
      storage: {
        rules: readFileSync(resolve(__dirname, "../../storage.rules"), "utf8"),
      },
    });
  });

  afterAll(async () => {
    await environment.cleanup();
  });

  it("allows an owner to upload protected incident images", async () => {
    const storage = environment.authenticatedContext("reporter").storage();
    const image = storage.ref("incident_media/incident-1/reporter/photo.jpg");

    await assertSucceeds(
      image.put(new Uint8Array([1, 2, 3]), {contentType: "image/jpeg"}),
    );
  });

  it("blocks another user from reading or replacing incident images", async () => {
    const reporter = environment.authenticatedContext("reporter").storage();
    const stranger = environment.authenticatedContext("stranger").storage();
    const path = "incident_media/incident-2/reporter/photo.jpg";

    await assertSucceeds(
      reporter
        .ref(path)
        .put(new Uint8Array([1, 2, 3]), {contentType: "image/jpeg"}),
    );
    await assertFails(stranger.ref(path).getDownloadURL());
    await assertFails(
      stranger
        .ref(path)
        .put(new Uint8Array([4, 5, 6]), {contentType: "image/jpeg"}),
    );
  });

  it("rejects non-image evidence uploads", async () => {
    const storage = environment.authenticatedContext("responder").storage();
    const evidence = storage.ref(
      "responder_evidence/responder/identity-document.txt",
    );

    await assertFails(
      evidence.put(new Uint8Array([1, 2, 3]), {contentType: "text/plain"}),
    );
  });
});
