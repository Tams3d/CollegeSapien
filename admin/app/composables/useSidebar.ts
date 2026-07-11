import { breakpointsTailwind, useBreakpoints } from "@vueuse/core";

const isOpen = ref(false);

export function useSidebar() {
  const breakpoints = useBreakpoints(breakpointsTailwind);
  const isDesktop = breakpoints.greaterOrEqual("lg");

  watch(
    isDesktop,
    v => {
      if (v) isOpen.value = false;
    },
    { immediate: true },
  );

  return {
    isOpen,
    isDesktop,
    toggle: () => (isOpen.value = !isOpen.value),
    open: () => (isOpen.value = true),
    close: () => (isOpen.value = false),
  };
}
