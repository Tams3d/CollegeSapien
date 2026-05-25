import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { app } from './app';
import { processResourceDocument } from './app/ai/ai.controller';

const geminiApiKey = defineSecret('GEMINI_API_KEY');
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
    secrets: [geminiApiKey, disableAppCheck],
  },
  app
);

export const processHubResource = onDocumentCreated(
  {
    document: 'hub_resources/{resourceId}',
    region: 'asia-south1',
    secrets: [geminiApiKey],
    memory: '512MiB',
    timeoutSeconds: 120,
    maxInstances: 5,
  },
  async (event) => {
    const data = event.data?.data() as Record<string, any> | undefined;
    if (!data) return;
    if (data.aiProcessed) return;

    await processResourceDocument(event.params.resourceId, data);
  }
);
