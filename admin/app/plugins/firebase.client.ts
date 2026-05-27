import { initializeApp, getApps } from "firebase/app";
import { getAuth, onAuthStateChanged } from "firebase/auth";

export default defineNuxtPlugin(() => {
  const config = useRuntimeConfig();

  const firebaseConfig = {
    apiKey: config.public.firebaseApiKey as string,
    authDomain: config.public.firebaseAuthDomain as string,
    projectId: config.public.firebaseProjectId as string,
    appId: config.public.firebaseAppId as string,
  };

  const app = getApps().length ? getApps()[0]! : initializeApp(firebaseConfig);
  const auth = getAuth(app);

  // Start auth listener immediately after Firebase is ready
  const authStore = useAuthStore();
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      const tokenResult = await user.getIdTokenResult(true);
      const role = (tokenResult.claims["role"] as string) ?? "user";
      authStore.setUser({
        uid: user.uid,
        email: user.email ?? "",
        name: user.displayName ?? user.email ?? "",
        role,
      });
    } else {
      authStore.clearUser();
    }
    authStore.markInitialized();
  });

  return {
    provide: {
      firebaseApp: app,
      firebaseAuth: auth,
    },
  };
});
