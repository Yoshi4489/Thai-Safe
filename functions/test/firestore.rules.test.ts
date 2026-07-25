import {readFileSync} from "node:fs";
import {resolve} from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {afterAll, beforeAll, describe, it} from "vitest";

const emulatorAvailable = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const describeWithEmulator = emulatorAvailable ? describe : describe.skip;

describeWithEmulator("Firestore security rules", () => {
  let environment: RulesTestEnvironment;

  beforeAll(async () => {
    environment = await initializeTestEnvironment({
      projectId: "thai-safe-rules-test",
      firestore: {
        rules: readFileSync(
          resolve(__dirname, "../../firestore.rules"),
          "utf8",
        ),
      },
    });
    await environment.withSecurityRulesDisabled(async (context) => {
      const firestore = context.firestore();
      await firestore.doc("incidents/test-incident").set({
        status: "pending",
        title: "Sanitized incident",
      });
      await firestore.doc("incident_private/test-incident").set({
        reporter_uid: "reporter",
        reporter_phone: "private",
      });
      await firestore.doc("users/reporter").set({
        id: "reporter",
        role: "user",
        first_name: "Test",
      });
    });
  });

  afterAll(async () => {
    await environment.cleanup();
  });

  it("lets signed-in users read sanitized incidents", async () => {
    const db = environment.authenticatedContext("ordinary-user").firestore();
    await assertSucceeds(db.doc("incidents/test-incident").get());
  });

  it("blocks ordinary users from incident status writes", async () => {
    const db = environment.authenticatedContext("ordinary-user").firestore();
    await assertFails(db.doc("incidents/test-incident").update({
      status: "resolved",
    }));
  });

  it("keeps private incident data reporter-only", async () => {
    const stranger = environment.authenticatedContext("stranger").firestore();
    const reporter = environment.authenticatedContext("reporter").firestore();
    await assertFails(stranger.doc("incident_private/test-incident").get());
    await assertSucceeds(reporter.doc("incident_private/test-incident").get());
  });

  it("prevents users from assigning themselves a role", async () => {
    const db = environment.authenticatedContext("reporter").firestore();
    await assertFails(db.doc("users/reporter").update({role: "admin"}));
  });
});
