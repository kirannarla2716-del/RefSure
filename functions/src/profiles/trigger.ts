import {getFirestore} from "firebase-admin/firestore";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {buildPublicProfile} from "./projection";

/**
 * Continuous projection trigger. Export this symbol from the deployment index
 * when profile projection is enabled for the Firebase project.
 */
export const projectPublicProfile = onDocumentWritten(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const userId = event.params.userId;
    const target = getFirestore().doc(`publicProfiles/${userId}`);
    const after = event.data?.after;

    if (!after?.exists) {
      await target.delete();
      return;
    }

    const projection = buildPublicProfile(
      userId,
      after.data() ?? {},
      after.updateTime,
    );
    await target.set(projection);
  },
);
