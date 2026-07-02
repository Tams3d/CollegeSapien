<script setup lang="ts">
interface CurriculumSubject {
  semester: string;
  parent_semester?: number | null;
  subject_code?: string;
  subject_name: string;
  course_type?: string;
  l_t_p?: string;
  tcp?: number | null;
  credits?: number | null;
  category?: string;
  is_elective?: boolean;
  elective_type?: string | null;
  record_type?: string;
  elective_stream?: string | null;
  options_from?: string | null;
}

interface Curriculum {
  id: string;
  collegeCode: string;
  courseCode: string;
  regulation: string;
  college: string;
  course: string;
  status: "pending" | "approved";
  fileName?: string | null;
  subjects: CurriculumSubject[];
}

const props = defineProps<{
  curriculum: Curriculum;
  actionInFlight?: boolean;
}>();

const emit = defineEmits<{
  close: [];
  approve: [id: string];
  reject: [id: string];
}>();

const effectiveSemester = (s: CurriculumSubject): number | null => {
  if (typeof s.parent_semester === "number") return s.parent_semester;
  const n = parseInt(s.semester, 10);
  return Number.isNaN(n) ? null : n;
};

const semesterGroups = computed(() => {
  const groups = new Map<number, CurriculumSubject[]>();
  for (const s of props.curriculum.subjects) {
    if (s.record_type === "option") continue;
    const sem = effectiveSemester(s);
    if (sem === null) continue;
    if (!groups.has(sem)) groups.set(sem, []);
    groups.get(sem)!.push(s);
  }
  return [...groups.entries()].sort((a, b) => a[0] - b[0]);
});

const optionGroups = computed(() => {
  const groups = new Map<string, CurriculumSubject[]>();
  for (const s of props.curriculum.subjects) {
    if (s.record_type !== "option") continue;
    const key = s.elective_type ?? "Elective Options";
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(s);
  }
  return [...groups.entries()];
});
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    @click.self="emit('close')"
  >
    <div
      class="bg-white rounded-xl shadow-xl w-full max-w-3xl max-h-[85vh] overflow-y-auto"
    >
      <div
        class="sticky top-0 bg-white px-6 py-4 border-b border-gray-100 flex items-start justify-between gap-4"
      >
        <div>
          <h3 class="text-base font-semibold text-gray-900">
            {{ curriculum.college }} · {{ curriculum.course }}
          </h3>
          <p class="text-sm text-gray-500 mt-0.5">
            {{ curriculum.collegeCode }} / {{ curriculum.courseCode }} /
            {{ curriculum.regulation }} ·
            {{ curriculum.subjects.length }} subjects
          </p>
        </div>
        <button
          class="shrink-0 p-1 text-gray-400 hover:text-gray-700"
          @click="emit('close')"
        >
          <Icon name="i-heroicons-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <div class="p-6 space-y-6">
        <div
          v-for="[semester, subjects] in semesterGroups"
          :key="`sem-${semester}`"
        >
          <h4 class="text-sm font-semibold text-gray-700 mb-2">
            Semester {{ semester }}
          </h4>
          <table class="w-full text-xs">
            <thead>
              <tr class="text-left text-gray-400 border-b border-gray-100">
                <th class="py-1.5 pr-2 font-medium">Code</th>
                <th class="py-1.5 pr-2 font-medium">Name</th>
                <th class="py-1.5 pr-2 font-medium">L-T-P</th>
                <th class="py-1.5 pr-2 font-medium">Credits</th>
                <th class="py-1.5 pr-2 font-medium">Category</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(s, idx) in subjects"
                :key="`${semester}-${idx}`"
                class="border-b border-gray-50"
              >
                <td class="py-1.5 pr-2 text-gray-500">
                  {{ s.subject_code || "—" }}
                </td>
                <td class="py-1.5 pr-2 text-gray-900">
                  {{ s.subject_name }}
                  <span
                    v-if="s.record_type === 'slot'"
                    class="ml-1 text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded-full"
                    >Elective slot</span
                  >
                </td>
                <td class="py-1.5 pr-2 text-gray-500">{{ s.l_t_p || "—" }}</td>
                <td class="py-1.5 pr-2 text-gray-500">
                  {{ s.credits ?? "—" }}
                </td>
                <td class="py-1.5 pr-2 text-gray-500">
                  {{ s.category || "—" }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-for="[pool, subjects] in optionGroups" :key="`pool-${pool}`">
          <h4 class="text-sm font-semibold text-gray-700 mb-2">
            {{ pool }} — options
          </h4>
          <table class="w-full text-xs">
            <thead>
              <tr class="text-left text-gray-400 border-b border-gray-100">
                <th class="py-1.5 pr-2 font-medium">Name</th>
                <th class="py-1.5 pr-2 font-medium">Stream</th>
                <th class="py-1.5 pr-2 font-medium">Credits</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="(s, idx) in subjects"
                :key="`${pool}-${idx}`"
                class="border-b border-gray-50"
              >
                <td class="py-1.5 pr-2 text-gray-900">{{ s.subject_name }}</td>
                <td class="py-1.5 pr-2 text-gray-500">
                  {{ s.elective_stream || "—" }}
                </td>
                <td class="py-1.5 pr-2 text-gray-500">
                  {{ s.credits ?? "—" }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div
        v-if="curriculum.status === 'pending'"
        class="sticky bottom-0 bg-white px-6 py-4 border-t border-gray-100 flex justify-end gap-2"
      >
        <button
          :disabled="actionInFlight"
          class="px-4 py-2 text-sm border border-red-300 text-red-600 rounded-lg hover:bg-red-50 disabled:opacity-60 transition-colors"
          @click="emit('reject', curriculum.id)"
        >
          Reject
        </button>
        <button
          :disabled="actionInFlight"
          class="px-4 py-2 text-sm bg-green-600 text-white font-medium rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
          @click="emit('approve', curriculum.id)"
        >
          Approve
        </button>
      </div>
    </div>
  </div>
</template>
