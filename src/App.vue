<template>
  <component :is="layout">
    <router-view></router-view>
  </component>
</template>
<script>
import MainLayout from "@/layout/MainLayout.vue";
import AuthLayout from "./layout/AuthLayout.vue";

export default {
  computed: {
    layout() {
      if (this.$route.meta.layout == "auth") {
        return AuthLayout;
      }
      return MainLayout;
    },
  },
  component: {
    MainLayout,
    AuthLayout,
  },
};
</script>

<style lang="css">
@import "~materialize-css/dist/css/materialize.min.css";
@import "./assets/index.css";
</style>
