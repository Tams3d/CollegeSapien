import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { app } from './app';
// import { processResourceDocument } from './app/ai/ai.controller';

// Gemini API key is currently disabled — do not bind it as a secret or
// Firebase will try to resolve it from Secret Manager at deploy time and fail.
// const geminiApiKey = defineSecret('GEMINI_API_KEY');
const disableAppCheck = defineSecret('DISABLE_APP_CHECK');

export const api = onRequest(
  {
    region: 'asia-south1',
    memory: '1GiB',
    timeoutSeconds: 300,
    concurrency: 80,
    minInstances: 0,
    maxInstances: 10,
    invoker: 'public',
    secrets: [disableAppCheck],
  },
  app
);

export const processHubResource = onDocumentCreated(
  {
    document: 'hub_resources/{resourceId}',
    region: 'asia-south1',
    memory: '512MiB',
    timeoutSeconds: 120,
    maxInstances: 5,
  },
  async event => {
    const data = event.data?.data() as Record<string, any> | undefined;
    if (!data) return;
    if (data.aiProcessed) return;

    // Gemini-backed AI processing is temporarily disabled (no API key).
    // Just mark as processed so uploads aren't stuck pending forever.
    await admin
      .firestore()
      .collection('hub_resources')
      .doc(event.params.resourceId)
      .update({ aiProcessed: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() })
      .catch(() => undefined);

    // await processResourceDocument(event.params.resourceId, data);
  }
);
