import { createRouter, createWebHashHistory } from "vue-router";
import pinia from "@/store";
import { useAuthStore } from "@/store/auth";
import { getToken } from "@/api/client";

const routes = [
  {
    path: "/login",
    name: "login",
    meta: {
      layout: "auth",
      auth: false,
    },
    component: () => import("../views/LoginApp.vue"),
  },
  {
    path: "/",
    name: "home",
    meta: {
      layout: "main",
      auth: true,
    },
    component: () => import("../views/HomePage.vue"),
    children: [
      {
        path: "/model",
        name: "model",
        component: () => import("../views/ModelApp.vue"),
      },
    ],
  },
  {
    path: "/profile",
    name: "profile",
    meta: {
      layout: "main",
      auth: true,
    },
    component: () => import("../views/ProfilePage.vue"),
  },
  {
    path: "/edit-shema",
    name: "edit-shema",
    meta: {
      layout: "main",
      auth: true,
    },
    component: () => import("../views/EditSchemaPage.vue"),
  },
  {
    path: "/magic-link",
    name: "magic-link",
    meta: {
      layout: "auth",
      auth: false,
    },
    component: () => import("../views/MagicLinkPage.vue"),
  },
];

const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes,
});

const authStore = useAuthStore(pinia);

router.beforeEach((to, _from, next) => {
  if (to.meta.auth) {
    const token = getToken();
    if (token) {
      next();
    } else if (authStore.isAuthenticated) {
      next();
    } else {
      next("/login");
    }
  } else {
    next();
  }
});

export default router;
