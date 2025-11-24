<template>
  <header class="navbar">
    <div class="navbar__brand" @click="refresh">
      <div class="logo" />
      <span class="navbar__title">IGGY Reservation</span>
    </div>
  </header>
</template>

<script setup>
import { useStore } from "vuex";

const store = useStore();

const refresh = () => {
  store.dispatch("fetchInfo").catch((error) => console.log(error));
};
</script>

<style lang="scss" scoped>
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #535353;
  color: #e5e7eb;
  padding: 6px 8px;
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
</style>
