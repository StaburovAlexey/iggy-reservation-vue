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
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
});

export default router;
