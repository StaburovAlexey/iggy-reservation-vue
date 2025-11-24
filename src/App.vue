<template>
  <component :is="layout">
    <router-view />
  </component>
</template>

<script setup>
import { computed } from "vue";
import { useRoute } from "vue-router";
import MainLayout from "@/layout/MainLayout.vue";
import AuthLayout from "@/layout/AuthLayout.vue";

const route = useRoute();

const layout = computed(() =>
  route.meta.layout === "auth" ? AuthLayout : MainLayout
);
</script>

<style lang="css">
@import "~materialize-css/dist/css/materialize.min.css";
@import "./assets/index.css";
</style>
