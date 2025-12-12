<template>
  <header class="navbar">
    <div class="navbar__brand" @click="refresh">
      <div class="logo" />
      <span class="navbar__title">IGGY Reservation</span>
    </div>
    <el-dropdown trigger="click">
      <div class="navbar__menu-btn">
        <el-avatar :size="36" :src="avatarUrl" class="navbar__avatar">{{ avatarFallback }}</el-avatar>
        <span class="navbar__name">{{ userName }}</span>
        <el-icon><ArrowDown /></el-icon>
      </div>
      <template #dropdown>
        <el-dropdown-menu class="navbar__dropdown">
          <el-dropdown-item class="navbar__user">
            <el-avatar :size="40" :src="avatarUrl" class="navbar__avatar">{{ avatarFallback }}</el-avatar>
            <div class="navbar__user-info">
              <div class="navbar__user-name">{{ userName }}</div>
              <div class="navbar__user-mail">{{ userEmail }}</div>
            </div>
          </el-dropdown-item>
          <el-dropdown-item divided @click="editProfile">
            Редактировать профиль
          </el-dropdown-item>
          <el-dropdown-item @click="toggleTheme">
            Сменить тему: {{ nextThemeLabel }}
          </el-dropdown-item>
          <el-dropdown-item divided @click="logout">
            Выйти из аккаунта
          </el-dropdown-item>
        </el-dropdown-menu>
      </template>
    </el-dropdown>
  </header>
</template>

<script setup>
import { computed, onMounted, ref, watch, defineEmits } from "vue";
import { useRouter } from "vue-router";
import { ArrowDown } from "@element-plus/icons-vue";
import { supabase } from "@/lib/supabaseClient";
import { storeToRefs } from "pinia";
import { useDataStore } from "@/store/dataBase";
import { useAuthStore } from "@/store/auth";

defineEmits(["open-room"]);

const dataStore = useDataStore();
const authStore = useAuthStore();
const { reservation } = storeToRefs(dataStore);
const { user } = storeToRefs(authStore);

const reservations = computed(() => reservation.value || []);
const isRoomReserved = computed(() =>
  reservations.value.some((item) => item.table === "12")
);

const router = useRouter();
const THEME_KEY = "iggy-theme";
const theme = ref(localStorage.getItem(THEME_KEY) || "dark");

const userName = computed(
  () => user.value?.user_metadata?.full_name || user.value?.email || "Пользователь"
);
const userEmail = computed(() => user.value?.email || "Нет e-mail");
const avatarUrl = computed(() => user.value?.user_metadata?.avatar_url || "");
const avatarFallback = computed(() =>
  userName.value ? userName.value.slice(0, 1).toUpperCase() : "U"
);

const applyTheme = (value) => {
  const root = document.documentElement;
  root.classList.remove("theme-light", "theme-dark");
  const normalized = value === "light" ? "light" : "dark";
  root.classList.add(`theme-${normalized}`);
  localStorage.setItem(THEME_KEY, normalized);
};

watch(
  theme,
  (value) => applyTheme(value),
  { immediate: true }
);

const nextThemeLabel = computed(() =>
  theme.value === "light" ? "Светлая тема" : "Темная тема"
);

const refresh = () => {
  dataStore.fetchInfo().catch((error) => console.log(error));
};

const toggleTheme = () => {
  theme.value = theme.value === "light" ? "dark" : "light";
};

const editProfile = () => {
  router.push("/profile");
};

const logout = async () => {
  try {
    await supabase.auth.signOut();
    authStore.clearUser();
  } catch (error) {
    console.log(error);
  } finally {
    router.push("/login");
  }
};

onMounted(async () => {
  const { data, error } = await supabase.auth.getUser();
  if (!error && data?.user) {
    authStore.setUser(data.user);
  }
});
</script>

<style lang="scss" scoped>
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--bg-navbar);
  color: var(--text-primary);
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

.navbar__menu-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  color: var(--text-primary);
}

.navbar__avatar {
  margin-right: 10px;
  background: var(--bg-surface-2);
  color: var(--text-primary);
}

.navbar__name {
  font-weight: 600;
  max-width: 140px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.navbar__dropdown {
  min-width: 220px;
}

.navbar__user {
  gap: 8px;
  cursor: default;
}

.navbar__user-info {
  display: flex;
  flex-direction: column;
}

.navbar__user-name {
  font-weight: 700;
}

.navbar__user-mail {
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
