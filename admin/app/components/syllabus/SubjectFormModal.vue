<script setup lang="ts">
interface CurriculumSubject {
  semester: number | null;
  subject_code?: string;
  subject_name: string;
  credits?: number | null;
  category?: string;
  elective_type?: string | null;
  record_type?: string;
}

const props = defineProps<{
  subject: CurriculumSubject;
  isNew: boolean;
}>();

const emit = defineEmits<{
  save: [subject: CurriculumSubject];
  cancel: [];
}>();

const form = reactive<CurriculumSubject>({ ...props.subject });

const recordTypeOptions = ["core", "elective", "option"];

const save = () => {
  if (!form.subject_name.trim()) return;
  if (
    form.record_type !== "option" &&
    (form.semester === undefined ||
      form.semester === null ||
      (form.semester as unknown as string) === "")
  ) {
    return;
  }
  emit("save", {
    ...form,
    subject_name: form.subject_name.trim(),
    semester: form.record_type === "option" ? null : Number(form.semester),
    credits:
      form.credits === undefined ||
      form.credits === null ||
      (form.credits as unknown as string) === ""
        ? null
        : Number(form.credits),
  });
};
</script>

<template>
  <Modal max-width="max-w-lg" z-index="z-[60]" @close="emit('cancel')">
    <div class="p-6">
      <h3 class="text-base font-semibold text-gray-900 mb-4">
        {{ isNew ? "Add subject" : "Edit subject" }}
      </h3>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div class="sm:col-span-2">
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Subject name *</label
          >
          <input
            v-model="form.subject_name"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Subject code</label
          >
          <input
            v-model="form.subject_code"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Record type</label
          >
          <select
            v-model="form.record_type"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          >
            <option v-for="rt in recordTypeOptions" :key="rt" :value="rt">
              {{ rt }}
            </option>
          </select>
        </div>

        <div v-if="form.record_type !== 'option'">
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Semester *</label
          >
          <input
            v-model.number="form.semester"
            type="number"
            placeholder="e.g. 5"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>



        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Credits</label
          >
          <input
            v-model="form.credits"
            type="number"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Category</label
          >
          <input
            v-model="form.category"
            placeholder="BS / HUM / ES (PC)"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Elective type</label
          >
          <input
            v-model="form.elective_type"
            placeholder="Programme Elective"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-5">
        <button
          class="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          @click="emit('cancel')"
        >
          Cancel
        </button>
        <button
          class="px-4 py-2 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors"
          @click="save"
        >
          {{ isNew ? "Add" : "Save" }}
        </button>
      </div>
    </div>
  </Modal>
</template>
