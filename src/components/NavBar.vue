<template>
  <header>
    <nav>
      <div class="nav-wrapper indigo darken-3">
        <a href="#!" class="brand-logo left logo white" @click.prevent="refresh" />
        <button
          class="btn right btn-nav modal-trigger"
          data-target="modal12"
          :class="{ red: isRoomReserved }"
        >
          Бронь зала
        </button>
      </div>
    </nav>
    <ModalApp
      :table="roomReservations"
      :numberTable="12"
      @del="delReserve"
      @creat="creatReserve"
    />
  </header>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import { useStore } from "vuex";
import ModalApp from "./ModalApp.vue";

const store = useStore();
const reservations = ref([]);
const loading = ref(false);

const date = computed(() => store.getters.date);
const storeReservations = computed(() => store.getters.reservation || []);

const roomReservations = computed(() =>
  reservations.value.filter((item) => item.table === "12")
);
const isRoomReserved = computed(() => roomReservations.value.length > 0);

const fetchReservations = async () => {
  if (!date.value) return;
  loading.value = true;
  try {
    const data = await store.dispatch("fetchInfo");
    reservations.value = data || [];
  } catch (error) {
    console.log(error);
  } finally {
    loading.value = false;
  }
};

const delReserve = async ({ id }) => {
  if (!id) return;
  loading.value = true;
  try {
    const status = await store.dispatch("delInfo", { id });
    if (status === 204 || status === "204") {
      await fetchReservations();
      alert("Бронь удалена");
    } else {
      alert(status);
    }
  } finally {
    loading.value = false;
  }
};

const creatReserve = async (data) => {
  loading.value = true;
  try {
    const status = await store.dispatch("creatInfo", { data });
    if (status === 201 || status === "201") {
      await fetchReservations();
      alert("Бронь создана");
    } else {
      alert(status);
    }
  } finally {
    loading.value = false;
  }
};

const refresh = () => fetchReservations();

watch(date, () => fetchReservations(), { immediate: true });
watch(
  storeReservations,
  (value) => {
    reservations.value = value;
  },
  { immediate: true, deep: true }
);
</script>

<style lang="scss"></style>
