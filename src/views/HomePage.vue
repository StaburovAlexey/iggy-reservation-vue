<template>

  <NavBar @open-room="openRoom" />
  <BarTheme ref="bar" class="page__content" />
  <FooterApp />

</template>

<script setup>
import { ref } from "vue";
import BarTheme from "@/components/BarTheme.vue";
import FooterApp from "@/components/FooterApp.vue";
import NavBar from "@/components/NavBar.vue";

const bar = ref(null);
const openRoom = () => bar.value?.openRoom();
</script>

<style lang="scss" scoped>
.page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.page__content {
  flex: 1 0 auto;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
}
</style>
