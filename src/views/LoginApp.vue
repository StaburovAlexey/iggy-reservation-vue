<template>
  <form class="card white" @submit.prevent="submit">
    <div class="card-content">
      <div class="center">
        <img class="logo-auth" src="../assets/logo-black.png" alt="logo" />
      </div>
      <div class="input-field">
        <i class="material-icons prefix">account_circle</i>
        <input id="icon_prefix" type="email" class="validate" v-model="email" />
        <label for="icon_prefix">Ваш e-mail</label>
      </div>
      <div class="input-field">
        <i class="material-icons prefix">border_color</i>
        <input id="password" type="password" class="validate" v-model="pass" />
        <label for="password">Пароль</label>
      </div>
      <div class="center">
        <PreloaderApp v-if="loading"></PreloaderApp>
        <button
          v-else
          class="btn waves-effect waves-light center"
          type="submit"
          name="action"
          :disabled="disabled"
        >
          Войти
          <i class="material-icons right">send</i>
        </button>
      </div>
    </div>
  </form>
</template>

<script>
import PreloaderApp from "@/components/PreloaderApp.vue";

export default {
  data() {
    return {
      email: "",
      pass: "",
      loading: false,
    };
  },
  methods: {
    async submit() {
      this.loading = true;
      const formData = {
        email: this.email,
        pass: this.pass,
      };
      try {
        await this.$store.dispatch("login", formData);
        this.$router.push("/");
        this.loading = false;
      } catch (e) {
        alert(e);
        console.log(e);
        this.loading = false;
      }
    },
  },
  computed: {
    disabled() {
      if (!this.email || !this.pass) {
        return true;
      }
      return false;
    },
  },
  components: { PreloaderApp },
};
</script>

<style lang="scss" scoped></style>
