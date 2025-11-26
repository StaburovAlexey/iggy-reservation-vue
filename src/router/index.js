import { supabase } from "@/lib/supabaseClient";
import { createRouter, createWebHistory } from "vue-router";

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
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

async function getUser(next) {
  let localUser = await supabase.auth.getSession();
  if (localUser.data.session == null) {
    next("/login");
  } else {
    next();
  }
}
router.beforeEach((to, from, next) => {
  if (to.meta.auth) {
    getUser(next);
  } else {
    next();
  }
});

export default router;
