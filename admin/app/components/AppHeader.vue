<script setup lang="ts">
const authStore = useAuthStore();
const { signOut } = useFirebaseAuth();
const router = useRouter();
const { toggle } = useSidebar();

const handleSignOut = async () => {
  await signOut();
  router.push("/login");
};
</script>

<template>
  <header
    class="h-14 bg-white border-b border-gray-200 flex items-center justify-between px-4 md:px-6 gap-3"
  >
    <div class="flex items-center gap-3 min-w-0">
      <button
        class="lg:hidden p-1.5 -ml-1.5 rounded-lg text-gray-500 hover:text-gray-900 hover:bg-gray-100"
        @click="toggle"
      >
        <Icon name="i-heroicons-bars-3" class="w-5 h-5" />
      </button>
      <div class="text-sm text-gray-500 truncate">
        <span class="hidden sm:inline">Welcome back, </span>
        <span class="font-semibold text-gray-900">{{
          authStore.user?.name
        }}</span>
      </div>
    </div>

    <div class="flex items-center gap-3 shrink-0">
      <RoleBadge :role="authStore.user?.role ?? 'user'" />
      <button
        class="text-sm text-gray-500 hover:text-gray-900 transition-colors flex items-center gap-1.5"
        @click="handleSignOut"
      >
        <Icon name="i-heroicons-arrow-right-on-rectangle" class="w-4 h-4" />
        Sign out
      </button>
    </div>
  </header>
</template>
