<template>
  <div class="auth">
    <el-card class="auth__card" shadow="hover">
      <div class="auth__logo">
        <img class="logo-auth" src="../assets/logo-black.png" alt="logo" />
      </div>
      <el-form :model="form" label-position="top" @submit.prevent>
        <el-form-item label="Ваш e-mail">
          <el-input v-model="form.email" type="email" placeholder="you@example.com" />
        </el-form-item>
        <el-form-item label="Пароль">
          <el-input v-model="form.pass" type="password" show-password />
        </el-form-item>
        <div class="auth__actions">
          <PreloaderApp v-if="loading" />
          <el-button
            v-else
            type="primary"
            size="large"
            :disabled="disabled"
            @click="submit"
          >
            Войти
          </el-button>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ElMessage } from "element-plus";
import { computed, reactive, ref } from "vue";
import { useRouter } from "vue-router";
import { useStore } from "vuex";
import PreloaderApp from "@/components/PreloaderApp.vue";

const store = useStore();
const router = useRouter();

const form = reactive({
  email: "",
  pass: "",
});
const loading = ref(false);

const disabled = computed(() => !form.email || !form.pass);

const submit = async () => {
  loading.value = true;
  try {
    await store.dispatch("login", { email: form.email, pass: form.pass });
    router.push("/");
  } catch (error) {
    ElMessage.error("Ошибка авторизации");
    console.log(error);
  } finally {
    loading.value = false;
  }
};
</script>

<style lang="scss" scoped>
.auth {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: linear-gradient(180deg, #0f172a 0%, #111827 100%);
}

.auth__card {
  width: 100%;
  max-width: 400px;
  background: #0b1220;
  color: #e5e7eb;
  border: 1px solid #1f2937;
}

.auth__logo {
  text-align: center;
  margin-bottom: 12px;
}

.logo-auth {
  width: 96px;
  height: auto;
}

.auth__actions {
  display: flex;
  justify-content: center;
  margin-top: 12px;
}
</style>
