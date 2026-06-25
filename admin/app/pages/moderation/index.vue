<script setup lang="ts">
definePageMeta({ layout: "admin", middleware: "auth" });

interface Resource {
  id: string;
  name: string;
  category: string;
  uploaderName?: string;
  uploadedBy?: string;
  collegeId?: string;
  createdAt?: string;
  fileUrl?: string;
  mimeType?: string;
  fileName?: string;
  sizeBytes?: number;
  department?: string;
  semester?: number;
  subjectName?: string;
  keywords?: string[];
  aiSuggestedCategory?: string | null;
  aiSpamFlag?: boolean;
}

const formatFileSize = (bytes?: number) => {
  if (!bytes) return '';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const fileTypeLabel = (mime?: string) => {
  if (!mime) return 'File';
  if (mime === 'application/pdf') return 'PDF';
  if (mime.startsWith('image/')) return 'Image';
  return 'File';
};

const { get, patch, delete: apiDelete } = useApi();

const resources = ref<Resource[]>([]);
const loading = ref(true);
const categoryFilter = ref("all");
const pendingReject = ref<Resource | null>(null);
const rejectReason = ref("");
const actionInFlight = ref<Set<string>>(new Set());
const detailResource = ref<Resource | null>(null);
const snack = ref("");

const fetchPending = async () => {
  loading.value = true;
  const query =
    categoryFilter.value !== "all" ? `?category=${categoryFilter.value}` : "";
  resources.value = await get<Resource[]>(`/admin/resources/pending${query}`);
  loading.value = false;
};

onMounted(fetchPending);
watch(categoryFilter, fetchPending);

const approve = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await patch(`/admin/resources/${id}/approve`);
    resources.value = resources.value.filter((r) => r.id !== id);
    if (detailResource.value?.id === id) detailResource.value = null;
    snack.value = "Resource approved.";
  } catch (err) {
    console.error("Failed to approve resource", err);
  }
  actionInFlight.value.delete(id);
};

const reject = async () => {
  if (!pendingReject.value) return;
  const id = pendingReject.value.id;
  actionInFlight.value.add(id);
  try {
    await patch(
      `/admin/resources/${id}/reject`,
      rejectReason.value ? { reason: rejectReason.value } : {},
    );
    resources.value = resources.value.filter((r) => r.id !== id);
    if (detailResource.value?.id === id) detailResource.value = null;
    snack.value = "Resource rejected and archived.";
  } catch (err) {
    console.error("Failed to reject resource", err);
  }
  pendingReject.value = null;
  rejectReason.value = "";
  actionInFlight.value.delete(id);
};

const archive = async (id: string) => {
  actionInFlight.value.add(id);
  try {
    await apiDelete(`/admin/resources/${id}`);
    resources.value = resources.value.filter((r) => r.id !== id);
    if (detailResource.value?.id === id) detailResource.value = null;
    snack.value = "Resource archived.";
  } catch (err) {
    console.error("Failed to archive resource", err);
  }
  actionInFlight.value.delete(id);
};
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-xl font-bold text-gray-900">Moderation Queue</h1>
      <select
        v-model="categoryFilter"
        class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none"
      >
        <option value="all">All categories</option>
        <option value="Notes">Notes</option>
        <option value="QP">Question Papers</option>
      </select>
    </div>

    <div
      v-if="snack"
      class="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2 flex justify-between"
    >
      {{ snack }}
      <button @click="snack = ''">
        <Icon name="i-heroicons-x-mark" class="w-4 h-4" />
      </button>
    </div>

    <div v-if="loading" class="text-gray-400 text-sm p-4">Loading…</div>

    <div
      v-else-if="resources.length === 0"
      class="bg-white rounded-xl border border-gray-200 p-8 text-center text-gray-500 text-sm"
    >
      No pending resources. 🎉
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="resource in resources"
        :key="resource.id"
        class="bg-white rounded-xl border border-gray-200 p-5"
      >
        <div class="flex items-start justify-between gap-2 mb-3">
          <div>
            <div class="font-semibold text-gray-900 text-sm">
              {{ resource.name }}
            </div>
            <div class="text-xs text-gray-500 mt-0.5">
              {{ resource.category }} · By
              {{ resource.uploaderName ?? resource.uploadedBy }}
            </div>
          </div>
          <div class="flex items-center gap-1.5 shrink-0">
            <span
              v-if="resource.aiSpamFlag"
              class="text-xs bg-red-100 text-red-700 px-2 py-0.5 rounded-full"
              >AI: Spam</span
            >
            <span
              class="text-xs bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded-full"
              >Pending</span
            >
          </div>
        </div>

        <div
          v-if="resource.fileName || resource.sizeBytes"
          class="text-xs text-gray-400 mb-3 flex items-center gap-1"
        >
          <Icon name="i-heroicons-document" class="w-3.5 h-3.5" />
          <span>{{ fileTypeLabel(resource.mimeType) }}</span>
          <span v-if="resource.sizeBytes"> · {{ formatFileSize(resource.sizeBytes) }}</span>
        </div>

        <div class="flex gap-2 flex-wrap">
          <button
            class="px-3 py-1.5 text-xs font-medium border border-blue-300 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors"
            @click="detailResource = resource"
          >
            View
          </button>
          <button
            v-if="resource.fileUrl"
            class="px-3 py-1.5 text-xs font-medium border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 transition-colors"
            @click.stop
          >
            <a
              :href="resource.fileUrl"
              target="_blank"
              rel="noopener noreferrer"
              class="flex items-center gap-1"
            >
              <Icon name="i-heroicons-arrow-top-right-on-square" class="w-3.5 h-3.5" />
              Open File
            </a>
          </button>
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
            @click="approve(resource.id)"
          >
            Approve
          </button>
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium border border-red-300 text-red-600 rounded-lg hover:bg-red-50 disabled:opacity-60 transition-colors"
            @click="
              pendingReject = resource;
              rejectReason = '';
            "
          >
            Reject
          </button>
          <button
            :disabled="actionInFlight.has(resource.id)"
            class="px-3 py-1.5 text-xs font-medium border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 disabled:opacity-60 transition-colors"
            @click="archive(resource.id)"
          >
            Archive
          </button>
        </div>
      </div>
    </div>

    <!-- Detail modal -->
    <div
      v-if="detailResource"
      class="fixed inset-0 z-40 flex items-center justify-center bg-black/40"
      @click.self="detailResource = null"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-lg mx-4 p-6 max-h-[90vh] overflow-y-auto">
        <div class="flex items-start justify-between mb-4">
          <h3 class="text-base font-semibold text-gray-900">{{ detailResource.name }}</h3>
          <button
            class="text-gray-400 hover:text-gray-600"
            @click="detailResource = null"
          >
            <Icon name="i-heroicons-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <div class="space-y-2 text-sm mb-5">
          <div class="flex justify-between">
            <span class="text-gray-500">Category</span>
            <span class="font-medium text-gray-900">{{ detailResource.category }}</span>
          </div>
          <div v-if="detailResource.department" class="flex justify-between">
            <span class="text-gray-500">Department</span>
            <span class="font-medium text-gray-900">{{ detailResource.department }}</span>
          </div>
          <div v-if="detailResource.semester" class="flex justify-between">
            <span class="text-gray-500">Semester</span>
            <span class="font-medium text-gray-900">{{ detailResource.semester }}</span>
          </div>
          <div v-if="detailResource.subjectName" class="flex justify-between">
            <span class="text-gray-500">Subject</span>
            <span class="font-medium text-gray-900">{{ detailResource.subjectName }}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-gray-500">Uploaded by</span>
            <span class="font-medium text-gray-900">{{ detailResource.uploaderName ?? detailResource.uploadedBy }}</span>
          </div>
          <div v-if="detailResource.fileName" class="flex justify-between">
            <span class="text-gray-500">File</span>
            <span class="font-medium text-gray-900">{{ detailResource.fileName }}</span>
          </div>
          <div v-if="detailResource.mimeType || detailResource.sizeBytes" class="flex justify-between">
            <span class="text-gray-500">Type / Size</span>
            <span class="font-medium text-gray-900">
              {{ fileTypeLabel(detailResource.mimeType) }}
              <span v-if="detailResource.sizeBytes"> · {{ formatFileSize(detailResource.sizeBytes) }}</span>
            </span>
          </div>
          <div v-if="detailResource.collegeId" class="flex justify-between">
            <span class="text-gray-500">College ID</span>
            <span class="font-medium text-gray-900">{{ detailResource.collegeId }}</span>
          </div>
        </div>

        <!-- AI analysis -->
        <div
          v-if="detailResource.aiSuggestedCategory || detailResource.aiSpamFlag"
          class="bg-gray-50 rounded-lg p-3 mb-5"
        >
          <div class="text-xs font-semibold text-gray-500 uppercase mb-2">AI Analysis</div>
          <div v-if="detailResource.aiSpamFlag" class="text-sm text-red-600 font-medium mb-1">
            Flagged as spam
          </div>
          <div v-if="detailResource.aiSuggestedCategory" class="text-sm text-gray-700">
            Suggested category:
            <span class="font-medium">{{ detailResource.aiSuggestedCategory }}</span>
            <span
              v-if="detailResource.aiSuggestedCategory !== detailResource.category"
              class="text-amber-600 ml-1"
            >(mismatch)</span>
          </div>
        </div>

        <!-- Keywords -->
        <div v-if="detailResource.keywords?.length" class="mb-5">
          <div class="text-xs font-semibold text-gray-500 uppercase mb-2">Keywords</div>
          <div class="flex flex-wrap gap-1.5">
            <span
              v-for="kw in detailResource.keywords"
              :key="kw"
              class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full"
            >{{ kw }}</span>
          </div>
        </div>

        <!-- Open file button -->
        <a
          v-if="detailResource.fileUrl"
          :href="detailResource.fileUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center justify-center gap-2 w-full px-4 py-2.5 mb-4 text-sm font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Icon name="i-heroicons-arrow-top-right-on-square" class="w-4 h-4" />
          Open File in New Tab
        </a>
        <div
          v-else
          class="text-center text-sm text-gray-400 mb-4 py-2"
        >
          No file URL available
        </div>

        <!-- Actions -->
        <div class="flex gap-2 border-t border-gray-100 pt-4">
          <button
            :disabled="actionInFlight.has(detailResource.id)"
            class="flex-1 px-3 py-2 text-sm font-medium bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-60 transition-colors"
            @click="approve(detailResource.id)"
          >
            Approve
          </button>
          <button
            :disabled="actionInFlight.has(detailResource.id)"
            class="flex-1 px-3 py-2 text-sm font-medium border border-red-300 text-red-600 rounded-lg hover:bg-red-50 disabled:opacity-60 transition-colors"
            @click="pendingReject = detailResource; rejectReason = '';"
          >
            Reject
          </button>
          <button
            :disabled="actionInFlight.has(detailResource.id)"
            class="flex-1 px-3 py-2 text-sm font-medium border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 disabled:opacity-60 transition-colors"
            @click="archive(detailResource.id)"
          >
            Archive
          </button>
        </div>
      </div>
    </div>

    <!-- Reject modal -->
    <div
      v-if="pendingReject"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    >
      <div class="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h3 class="text-base font-semibold text-gray-900 mb-2">
          Reject resource
        </h3>
        <p class="text-sm text-gray-500 mb-3">{{ pendingReject.name }}</p>
        <textarea
          v-model="rejectReason"
          placeholder="Reason (optional)"
          rows="3"
          class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm resize-none focus:outline-none mb-4"
        />
        <div class="flex justify-end gap-2">
          <button
            class="px-4 py-2 text-sm border border-gray-300 rounded-lg"
            @click="pendingReject = null"
          >
            Cancel
          </button>
          <button
            class="px-4 py-2 text-sm bg-red-600 text-white font-medium rounded-lg hover:bg-red-700"
            @click="reject"
          >
            Reject & Archive
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
