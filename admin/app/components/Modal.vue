<script setup lang="ts">
withDefaults(
  defineProps<{
    maxWidth?: string;
    zIndex?: string;
  }>(),
  {
    maxWidth: "max-w-sm",
    zIndex: "z-50",
  },
);

const emit = defineEmits<{
  close: [];
}>();
</script>

<template>
  <div
    class="fixed inset-0 flex items-center justify-center bg-black/40 p-4"
    :class="zIndex"
    @click.self="emit('close')"
  >
    <div
      class="bg-white rounded-xl shadow-xl w-full max-h-[85vh] overflow-y-auto"
      :class="maxWidth"
    >
      <slot />
    </div>
  </div>
</template>
