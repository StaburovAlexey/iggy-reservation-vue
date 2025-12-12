import { defineStore } from "pinia";
import { api } from "@/api/client";

const USER_STORAGE_KEY = "iggy.reserve.user";

const loadUserFromStorage = () => {
  try {
    const raw = localStorage.getItem(USER_STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch (_e) {
    return {};
  }
};

const saveUserToStorage = (user) => {
  try {
    if (user && Object.keys(user).length) {
      localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user));
    } else {
      localStorage.removeItem(USER_STORAGE_KEY);
    }
  } catch (_e) {
    /* ignore */
  }
};

export const useAuthStore = defineStore("auth", {
  state: () => ({
    user: loadUserFromStorage(),
  }),
  actions: {
    async login(credentials) {
      const payload = {
        login: credentials.login || credentials.email,
        password: credentials.password || credentials.pass,
      };
      const result = await api.login(payload);
      if (result?.user) {
        this.setUser(result.user);
      }
      return result;
    },
    logout() {
      api.logout();
      this.clearUser();
    },
    setUser(user) {
      this.user = user || {};
      saveUserToStorage(this.user);
    },
    clearUser() {
      this.user = {};
      saveUserToStorage(null);
    },
  },
  getters: {
    isAuthenticated: (state) => Boolean(state.user?.uuid),
  },
});
