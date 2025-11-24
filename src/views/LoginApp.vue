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
        <PreloaderApp v-if="loading" />
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

<script setup>
import { computed, ref } from "vue";
import { useRouter } from "vue-router";
import { useStore } from "vuex";
import PreloaderApp from "@/components/PreloaderApp.vue";

const store = useStore();
const router = useRouter();

const email = ref("");
const pass = ref("");
const loading = ref(false);

const disabled = computed(() => !email.value || !pass.value);

const submit = async () => {
  loading.value = true;
  try {
    await store.dispatch("login", { email: email.value, pass: pass.value });
    router.push("/");
  } catch (error) {
    alert(error);
    console.log(error);
  } finally {
    loading.value = false;
  }
};
</script>

<style lang="scss" scoped></style>
