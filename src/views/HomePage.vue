<template>
  <p class="black-text" @click="logout">{{ user }}</p>
  <NavBar></NavBar>
  <BarTheme></BarTheme>
  <FooterApp></FooterApp>
</template>

<script>
import BarTheme from '@/components/BarTheme.vue';
import FooterApp from '@/components/FooterApp.vue';
import NavBar from '@/components/NavBar.vue';
import { supabase } from "@/lib/supabaseClient";
export default {
  methods: {
    async logout() {
      await supabase.auth.signOut();
    }
  },
  components: { NavBar, BarTheme, FooterApp },
  computed: {
    user() {
      return this.$store.getters.user;
    },
  },
}
</script>

<style lang="scss" scoped></style>
