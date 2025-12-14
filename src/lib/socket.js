import { io } from "socket.io-client";
import { API_BASE_URL, getToken } from "@/api/client";

let socket = null;

const buildBaseUrl = () => {
  const envUrl = (import.meta.env.VITE_APP_API || API_BASE_URL || "").trim();
  if (envUrl) {
    try {
      const parsed = new URL(envUrl.startsWith("http") ? envUrl : `http://${envUrl}`);
      return parsed.origin;
    } catch (_) {
      return envUrl.replace(/\/+$/, "");
    }
  }
  if (typeof window !== "undefined") {
    return window.location.origin;
  }
  return "";
};

export const getSocket = () => {
  if (socket) return socket;
  const url = buildBaseUrl();
  socket = io(url, {
    transports: ["websocket", "polling"],
    auth: { token: getToken() },
    autoConnect: true,
  });
  socket.on("connect_error", (err) => {
    console.log("socket connect_error", err?.message || err);
  });
  return socket;
};

export const refreshSocketAuth = () => {
  if (!socket) return;
  socket.auth = { token: getToken() };
  if (socket.connected) {
    socket.disconnect();
  }
  socket.connect();
};

export const disconnectSocket = () => {
  if (!socket) return;
  socket.removeAllListeners();
  socket.disconnect();
  socket = null;
};
