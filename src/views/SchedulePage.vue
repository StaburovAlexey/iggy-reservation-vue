<template>

  <div class="schedule-page">

    <NavBar />

    <div class="schedule-page__body">

      <div class="schedule-grid">

        <el-card class="schedule-grid__calendar" shadow="hover" v-loading="loading">

          <div class="schedule-card__header">

            <div>

              <h2 class="schedule-card__title">���������� ����</h2>

              <p class="schedule-card__subtitle">

                ��������, �������� � ������� ����� ���� �������������, ������������� ����� ������ �����.

              </p>

            </div>

            <div class="schedule-card__controls">

              <el-date-picker v-model="visibleMonth" type="month" format="MMMM YYYY" value-format="YYYY-MM"
                :clearable="false" :editable="false" placeholder="�����" @change="handleMonthPickerChange" />

              <div class="schedule-card__buttons">

                <el-button size="small" @click="shiftMonth(-1)">����������</el-button>

                <el-button size="small" @click="goToday">�������</el-button>

                <el-button size="small" @click="shiftMonth(1)">���������</el-button>

                <el-button size="small" :icon="Refresh" :loading="loading" circle @click="refreshSchedule" />

              </div>

            </div>

          </div>



          <div class="schedule-card__scroll">

            <el-calendar v-model="calendarValue" :range="calendarRange" @panel-change="handlePanelChange">

              <template #date-cell="{ data }">

                <div class="schedule-date" :class="{ 'is-today': isToday(data.day) }">

                  <div class="schedule-date__header">

                    <span class="schedule-date__day">{{ dayNumber(data.day) }}</span>

                    <el-tag v-if="hasAssignments(data.day)" size="small" effect="plain" type="info" round>

                      {{ totalAssignments(data.day) }}

                    </el-tag>

                  </div>

                  <div class="schedule-date__groups">

                    <div v-for="group in previewGroups(data.day)" :key="group.key" class="schedule-date__group"
                      @dragover.prevent @drop="handleGroupDrop(data.day, group.key)">

                      <div class="schedule-date__group-name">{{ group.label }}</div>

                      <div class="schedule-date__people">

                        <el-tag v-for="person in group.people.slice(0, 2)" :key="person.id" :type="group.tag"
                          size="small" round :closable="isAdmin"
                          @close.stop="removePersonFromDate(data.day, group.key, person.id)">

                          <div class="schedule-date__person">

                            <el-avatar size="18" :src="person.avatar" class="schedule-date__person-avatar">

                              {{ person.name ? person.name.charAt(0).toUpperCase() : "" }}

                            </el-avatar>

                            <span class="schedule-date__person-name">{{ person.name }}</span>

                          </div>

                        </el-tag>

                        <span v-if="group.people.length > 2" class="schedule-date__more">

                          +{{ group.people.length - 2 }}

                        </span>

                      </div>

                    </div>

                  </div>

                </div>

              </template>

            </el-calendar>

          </div>

        </el-card>



        <el-card class="schedule-grid__employees" shadow="hover">

          <div class="employee-header">

            <h3>����������</h3>

            <p class="employee-hint">���������� ���������� �� ������ ������ ������ ���.</p>

          </div>

          <div class="employee-list">

            <el-tag v-for="emp in employees" :key="emp.id" class="employee-pill" effect="plain" type="info"
              :draggable="true" @dragstart="handleDragStart($event, emp)" @dragend="handleDragEnd">

              <div class="employee-pill__content">

                <el-avatar size="18" :src="emp.avatar" class="employee-pill__avatar">

                  {{ emp.name ? emp.name.charAt(0).toUpperCase() : "" }}

                </el-avatar>

                <span class="employee-pill__name">{{ emp.name }}</span>

              </div>

            </el-tag>

            <el-empty v-if="!employees.length" description="��� �����������"></el-empty>

          </div>

        </el-card>

      </div>

    </div>

  </div>

</template>



<script setup>

import { computed, onMounted, ref, watch } from "vue";

import dayjs from "dayjs";

import { ElMessage } from "element-plus";

import { Refresh } from "@element-plus/icons-vue";

import NavBar from "@/components/NavBar.vue";

import { api } from "@/api/client";

import { useAuthStore } from "@/store/auth";



const GROUPS = [

  { key: "opening", label: "��������", tag: "success" },

  { key: "closing", label: "��������", tag: "warning" },

  { key: "helpers", label: "�������", tag: "info", hint: "��� �������" },

];



const authStore = useAuthStore();

const isAdmin = computed(

  () => authStore.user?.role === "admin" || authStore.user?.user_metadata?.role === "admin"

);



const currentMonth = ref(dayjs().startOf("month"));

const calendarValue = ref(currentMonth.value.toDate());

const visibleMonth = ref(currentMonth.value.format("YYYY-MM"));

const calendarRange = computed(() => {

  const start = currentMonth.value.startOf("month").startOf("week").toDate();

  const end = currentMonth.value.endOf("month").endOf("week").toDate();

  return [start, end];

});



const loading = ref(false);

const employees = ref([]);

const employeesLoading = ref(false);

const draggingEmployee = ref(null);

const scheduleMap = ref({});



const getEmployeeAvatarById = (id) => {

  if (!id) return "";

  const found = (employees.value || []).find(

    (emp) =>

      emp?.uuid === id

  );

  return found?.avatar || "";

};



const unwrapUser = (value) => (value && value.user ? value.user : value);



// Expect a flat user object: { uuid, name, login, avatar }
const resolveAvatar = (raw) => {
  const item = unwrapUser(raw);
  if (!item || typeof item === "string") return "";
  return item.avatar || "";
};


const normalizePeople = (list = [], groupKey = "") => {

  if (!Array.isArray(list)) return [];

  return list

    .map((raw, index) => {

      const item = unwrapUser(raw);

      if (!item) return null;

      const name = item.name || item.login || (typeof item === "string" ? item : "");

      const cleaned = String(name || "").trim();

      if (!cleaned) return null;

      const id = item.uuid || item.id || item.user_id || item.login || `${groupKey}-${index}-${cleaned}`;

      const avatar = resolveAvatar(item) || getEmployeeAvatarById(id);

      return { id, name: cleaned, avatar };

    })

    .filter(Boolean);

};



const normalizeEmployee = (raw) => {

  const item = unwrapUser(raw);

  if (!item) return null;

  const name = item.name || item.login || (typeof item === "string" ? item : "");

  const cleaned = String(name || "").trim();

  if (!cleaned) return null;

  const id = item.uuid || item.id || item.user_id || item.login || cleaned;

  return { id, name: cleaned, avatar: resolveAvatar(item) };

};



const emptyDay = () => ({

  opening: [],

  closing: [],

  helpers: [],

});



const formatDateKey = (value) => dayjs(value).format("YYYY-MM-DD");



const applySchedule = (payload) => {

  const raw = payload?.items || payload?.schedule || payload || [];

  const next = {};

  (Array.isArray(raw) ? raw : []).forEach((item) => {

    const dateValue = item?.date || item?.day || item?.date_key || item?.dateKey;

    if (!dateValue) return;

    const key = formatDateKey(dateValue);

    next[key] = {

      opening: normalizePeople(item.opening || item.open || item.morning, "opening"),

      closing: normalizePeople(item.closing || item.close || item.evening, "closing"),

      helpers: normalizePeople(

        item.helpers || item.support || item.extra || item.other || item.others,

        "helpers"

      ),

    };

  });

  scheduleMap.value = next;

};



const loadEmployees = async () => {

  employeesLoading.value = true;

  try {

    const resp = await api.getEmployees();

    const list = resp?.items || resp?.users || resp || [];

    employees.value = (Array.isArray(list) ? list : []).map(normalizeEmployee).filter(Boolean);

  } catch (error) {

    console.log(error);

    ElMessage.error("�� ������� ��������� ������ �����������");

  } finally {

    employeesLoading.value = false;

  }

};



const fetchSchedule = async () => {

  loading.value = true;

  try {

    const month = currentMonth.value.format("YYYY-MM");

    const resp = await api.getSchedule({ month });

    applySchedule(resp);

  } catch (error) {

    console.log(error);

    ElMessage.error("�� ������� ��������� ����������");

  } finally {

    loading.value = false;

  }

};



const updateMonth = (value, { syncValue = false } = {}) => {

  const next = dayjs(value || new Date()).startOf("month");

  if (!next.isValid()) return;

  const changed = !next.isSame(currentMonth.value, "month");

  currentMonth.value = next;

  visibleMonth.value = next.format("YYYY-MM");

  if (syncValue) {

    calendarValue.value = next.toDate();

  }

  if (changed) {

    fetchSchedule();

  }

};



const handlePanelChange = (value) => updateMonth(value);



const handleMonthPickerChange = (value) => {

  if (!value) return;

  const picked = dayjs(value, "YYYY-MM");

  updateMonth(picked, { syncValue: true });

};



const goToday = () => updateMonth(dayjs(), { syncValue: true });

const shiftMonth = (delta) => updateMonth(currentMonth.value.add(delta, "month"), { syncValue: true });

const refreshSchedule = () => fetchSchedule();



watch(calendarValue, (value) => {

  if (!value) return;

  updateMonth(value);

});



const getDayData = (date) => {

  const key = formatDateKey(date);

  return scheduleMap.value[key] || emptyDay();

};



const serializeGroupForSave = (list = []) =>

  (list || [])

    .map((raw) => {

      const item = unwrapUser(raw);

      if (!item) return null;

      const uuid = item.uuid || item.id || item.user_id || item.login || null;

      if (!uuid) return null;

      return { uuid };

    })

    .filter(Boolean);



const saveDayData = async (dateKey) => {

  const entry = scheduleMap.value[dateKey] || emptyDay();

  const payload = {

    date: dateKey,

    opening: serializeGroupForSave(entry.opening),

    closing: serializeGroupForSave(entry.closing),

    helpers: serializeGroupForSave(entry.helpers),

  };

  try {

    await api.saveScheduleForDate(dateKey, payload);

    ElMessage.success("���������� ���������");

  } catch (error) {

    console.log(error);

    ElMessage.error("�� ������� ��������� ����������");

  }

};



const ensureDayEntry = (key) => {

  if (!scheduleMap.value[key]) {

    scheduleMap.value = { ...scheduleMap.value, [key]: emptyDay() };

  }

  return scheduleMap.value[key];

};



const normalizeDroppedEmployee = (rawEmployee) => {

  const employee = unwrapUser(rawEmployee);

  if (!employee) return null;

  const name = employee.name || employee.login || "";

  const cleaned = String(name || "").trim();

  if (!cleaned) return null;

  const id = employee.uuid || employee.id || employee.user_id || employee.login || cleaned;

  const avatar = employee.avatar || resolveAvatar(employee) || getEmployeeAvatarById(id);

  return { id, name: cleaned, avatar };

};



const addEmployeeToDate = (dateKey, groupKey, employee) => {

  const normalized = normalizeDroppedEmployee(employee);

  if (!normalized) return false;

  const dayEntry = ensureDayEntry(dateKey);

  const list = dayEntry[groupKey] || [];

  const exists = list.some((item) => item.id === normalized.id || item.name === normalized.name);

  if (exists) return false;

  const updatedGroup = [...list, normalized];

  const updatedEntry = { ...dayEntry, [groupKey]: updatedGroup };

  scheduleMap.value = { ...scheduleMap.value, [dateKey]: updatedEntry };

  return true;

};



const removePersonFromDate = async (date, groupKey, personId) => {

  if (!isAdmin.value) return;

  const dateKey = formatDateKey(date);

  const dayEntry = scheduleMap.value[dateKey];

  if (!dayEntry) return;

  const updatedGroup = (dayEntry[groupKey] || []).filter((person) => person.id !== personId);

  const updatedEntry = { ...dayEntry, [groupKey]: updatedGroup };

  scheduleMap.value = { ...scheduleMap.value, [dateKey]: updatedEntry };

  await saveDayData(dateKey);

};



const handleDragStart = (event, employee) => {

  draggingEmployee.value = employee;

  if (event.dataTransfer) {

    event.dataTransfer.effectAllowed = "copy";

    event.dataTransfer.setData("text/plain", employee.id || employee.name || "");

  }

};



const handleDragEnd = () => {

  draggingEmployee.value = null;

};



const handleGroupDrop = async (date, groupKey) => {

  if (!isAdmin.value) {

    ElMessage.warning("������������� ���������� ����� ������ �����");

    return;

  }

  if (!draggingEmployee.value) return;

  const dateKey = formatDateKey(date);

  const added = addEmployeeToDate(dateKey, groupKey, draggingEmployee.value);

  draggingEmployee.value = null;

  if (added) {

    await saveDayData(dateKey);

  } else {

    ElMessage.info("��������� ��� ������������ � ���� ������");

  }

};



const hasAssignments = (date) => {

  const data = getDayData(date);

  return GROUPS.some((group) => (data[group.key] || []).length);

};



const totalAssignments = (date) => {

  const data = getDayData(date);

  return GROUPS.reduce((acc, group) => acc + (data[group.key]?.length || 0), 0);

};



const previewGroups = (date) => {

  const data = getDayData(date);

  return GROUPS.map((group) => ({

    ...group,

    people: data[group.key] || [],

  }));

};



const dayNumber = (date) => dayjs(date).date();

const isToday = (date) => dayjs(date).isSame(dayjs(), "day");



onMounted(() => {

  fetchSchedule();

  loadEmployees();

});

</script>



<style scoped lang="scss">
.schedule-page {

  height: 100vh;

  display: flex;

  flex-direction: column;

  background: radial-gradient(circle at 10% 20%, rgba(255, 255, 255, 0.06), transparent 30%),

    radial-gradient(circle at 90% 10%, rgba(255, 255, 255, 0.05), transparent 25%),

    linear-gradient(180deg, var(--gradient-start) 0%, var(--gradient-end) 100%);

}



.schedule-page__body {

  flex: 1;

  padding: 20px 16px;

  display: flex;

  flex-direction: column;

  min-height: 0;

}



.schedule-grid {

  flex: 1;

  min-height: 0;

  display: grid;

  grid-template-columns: minmax(0, 1.5fr) minmax(260px, 0.7fr);

  gap: 16px;

}



.schedule-grid__calendar {

  background: var(--bg-surface-2);

  border: 1px solid var(--border-color);



  display: flex;

  flex-direction: column;

  height: 100%;

  min-height: 0;

}

:deep(.schedule-grid__calendar .el-card__body) {

  display: flex;

  flex-direction: column;

  gap: 12px;

  min-height: 0;

}

:deep(.el-calendar-table .el-calendar-day:hover) {

  background: transparent;

  transform: none;

}

:deep(.el-calendar-table .el-calendar-day) {

  height: auto !important;

}



.schedule-grid__employees {

  background: var(--bg-surface-2);

  border: 1px solid var(--border-color);

  display: flex;

  flex-direction: column;

  gap: 12px;

}



.employee-header {

  margin-bottom: 6px;



}



.employee-header h3 {

  color: var(--text-primary);

  margin: 0;

}



.employee-hint {

  margin: 4px 0 0;

  color: var(--text-secondary);

  font-size: 12px;

}



.employee-list {

  display: flex;

  flex-wrap: wrap;

  gap: 8px;

  min-height: 60px;

  align-items: flex-start;

}



.employee-pill {

  cursor: grab;

  user-select: none;

}



.employee-pill__content {

  display: inline-flex;

  align-items: center;

  gap: 6px;

}



.employee-pill__avatar {

  flex-shrink: 0;

  height: 18px;

  width: 18px;

  font-size: 10px;

}



.employee-pill__name {

  font-size: 12px;

  white-space: nowrap;

}



.schedule-card__header {

  display: flex;

  align-items: center;

  justify-content: space-between;

  gap: 12px;

  flex-wrap: wrap;

  margin-bottom: 12px;

}



.schedule-card__title {

  margin: 0;

  color: var(--text-primary);

}



.schedule-card__subtitle {

  margin: 4px 0 0;

  color: var(--text-secondary);

}



.schedule-card__controls {

  display: flex;

  align-items: center;

  gap: 8px;

  flex-wrap: wrap;

}



.schedule-card__scroll {

  flex: 1;

  min-height: 0;

  overflow: auto;

}



.schedule-card__scroll :deep(.el-calendar) {

  min-height: 0;

}



.schedule-card__buttons {

  display: flex;

  gap: 6px;

  flex-wrap: wrap;

}



.schedule-date {

  min-height: 120px;

  border-radius: 10px;

  padding: 6px;

  transition: background 0.2s ease, transform 0.15s ease, border-color 0.2s ease;

  border: 1px solid transparent;

  cursor: default;

}



.schedule-date.is-today {

  border-color: #409eff;

}



.schedule-date__header {

  display: flex;

  align-items: center;

  justify-content: space-between;

  margin-bottom: 6px;

  gap: 6px;

}



.schedule-date__day {

  font-weight: 700;

}



.schedule-date__groups {

  display: flex;

  flex-direction: column;

  gap: 6px;

}



.schedule-date__group {

  display: flex;

  flex-direction: column;

  gap: 2px;

  padding: 4px 0;

  border-bottom: 1px dashed transparent;

}



.schedule-date__group:hover {

  border-color: rgba(255, 255, 255, 0.2);

}



.schedule-date__group-name {

  font-size: 12px;

  color: var(--text-secondary);

}



.schedule-date__person {

  display: inline-flex;

  align-items: center;

  gap: 6px;

  max-width: 100%;

}



.schedule-date__person-avatar {

  flex-shrink: 0;

  height: 18px;

  width: 18px;

  font-size: 10px;

}



.schedule-date__person-name {

  font-size: 12px;

  white-space: nowrap;

  display: inline-block;

  overflow: hidden;

  text-overflow: ellipsis;

  max-width: 100%;

}



.schedule-date__people {

  display: flex;

  justify-content: space-around;

  align-items: center;

  gap: 4px;

  flex-wrap: wrap;

}



/* keep tags within the cell width so dragged items don't overflow */

.schedule-date__people :deep(.el-tag) {

  max-width: 100%;

  min-width: 0;

  box-sizing: border-box;

}



.schedule-date__people :deep(.el-tag__content) {

  width: 80%;

}



.schedule-date__more {

  font-size: 12px;

  color: var(--text-secondary);

}



@media (max-width: 960px) {

  .schedule-grid {

    grid-template-columns: 1fr;

  }



  .schedule-grid__employees {

    order: -1;

  }



  .employee-list {

    justify-content: flex-start;

  }

}
</style>
