<template>
  <div class="main-layout">
    <NavBar></NavBar>
    <BarTheme></BarTheme>
    <FooterApp></FooterApp>

  </div>
</template>

<script>
import BarTheme from '@/components/BarTheme.vue';
import FooterApp from '@/components/FooterApp.vue';
import NavBar from '@/components/NavBar.vue';

export default {
  components: { NavBar, BarTheme, FooterApp }
}
</script>

<style lang="scss" scoped></style>
