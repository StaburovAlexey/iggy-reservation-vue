<template>
  <NavBar @open-room="openRoom" />
  <BarTheme ref="bar" />
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

<style lang="scss" scoped></style>
