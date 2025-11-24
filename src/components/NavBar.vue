<template>
  <header class="navbar">
    <div class="navbar__brand" @click="refresh">
      <div class="logo" />
      <span class="navbar__title">IGGY Reservation</span>
    </div>
    <div class="navbar__actions">
      <el-tag :type="isRoomReserved ? 'danger' : 'success'" effect="dark">
        {{ isRoomReserved ? "Зал занят" : "Зал свободен" }}
      </el-tag>
      <el-button
        type="primary"
        :plain="!isRoomReserved"
        @click="$emit('open-room')"
      >
        Бронь зала
      </el-button>
    </div>
  </header>
</template>

<script setup>
import { computed } from "vue";
import { useStore } from "vuex";

defineEmits(["open-room"]);

const store = useStore();

const reservations = computed(() => store.getters.reservation || []);
const isRoomReserved = computed(() =>
  reservations.value.some((item) => item.table === "12")
);

const refresh = () => {
  store.dispatch("fetchInfo").catch((error) => console.log(error));
};
</script>

<style lang="scss" scoped>
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #111827;
  color: #e5e7eb;
  padding: 12px 16px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.navbar__brand {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.navbar__title {
  font-weight: 700;
  letter-spacing: 0.5px;
}

.logo {
  background-image: url("../assets/logo__white.png");
  background-position: center;
  background-repeat: no-repeat;
  background-size: contain;
  width: 40px;
  height: 40px;
}

.navbar__actions {
  display: inline-flex;
  align-items: center;
  gap: 12px;
}
</style>
