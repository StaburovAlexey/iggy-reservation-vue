const API_BASE_URL = (import.meta.env.VITE_APP_API || "").trim();
const TOKEN_STORAGE_KEY = "iggy.reserve.token";

if (!API_BASE_URL) {
  console.warn("VITE_APP_API is not set. API requests will fail until it is provided.");
}

const canUseStorage = () => typeof window !== "undefined" && typeof localStorage !== "undefined";
const now = () => (typeof performance !== "undefined" && performance.now ? performance.now() : Date.now());

const buildUrl = (path = "", params = {}) => {
  if (!API_BASE_URL) {
    throw new Error("API base URL is missing. Set VITE_APP_API in your environment.");
  }

  const url = new URL(path, API_BASE_URL);
  Object.entries(params || {})
    .filter(([, value]) => value !== undefined && value !== null)
    .forEach(([key, value]) => url.searchParams.append(key, value));

  return url;
};

const loadToken = () => (canUseStorage() ? localStorage.getItem(TOKEN_STORAGE_KEY) : null);
let authToken = loadToken();

const setToken = (token, persist = true) => {
  authToken = token || null;
  if (!canUseStorage()) {
    return authToken;
  }
  if (token && persist) {
    localStorage.setItem(TOKEN_STORAGE_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
  }
  return authToken;
};

const clearToken = () => setToken(null, false);
const getToken = () => authToken;

export const apiRequest = async (path, options = {}) => {
  const { method = "GET", params, body, headers, token, auth = true, signal } = options;
  const url = buildUrl(path, params);
  const startedAt = now();
  const payload = body;
  const isFormData = payload instanceof FormData;
  const requestHeaders = {
    ...headers,
  };

  const bearer = auth === false ? null : token || authToken;
  if (bearer) {
    requestHeaders.Authorization = `Bearer ${bearer}`;
  }
  if (!isFormData && payload !== undefined && payload !== null && method !== "GET") {
    requestHeaders["Content-Type"] = "application/json";
  }

  const requestInit = {
    method,
    headers: requestHeaders,
    signal,
  };

  if (payload !== undefined && payload !== null && method !== "GET") {
    requestInit.body = isFormData ? payload : JSON.stringify(payload);
  }

  console.info("[API] ->", method, url.toString(), {
    params,
    body: isFormData ? "[FormData]" : payload,
  });

  try {
    const response = await fetch(url, requestInit);
    const duration = Math.round(now() - startedAt);
    const contentType = response.headers.get("content-type") || "";
    const text = await response.text();
    const isJson = contentType.includes("application/json");
    const data = isJson && text ? JSON.parse(text) : text || null;

    console.info("[API] <-", method, url.toString(), response.status, `${duration}ms`);

    if (!response.ok) {
      const error = new Error(`API request failed with status ${response.status}`);
      error.status = response.status;
      error.response = data;
      throw error;
    }

    return data;
  } catch (error) {
    const duration = Math.round(now() - startedAt);
    console.error("[API] x", method, url.toString(), `${duration}ms`, error);
    throw error;
  }
};

export const apiClient = {
  request: apiRequest,
  get: (path, options = {}) => apiRequest(path, { ...options, method: "GET" }),
  post: (path, options = {}) => apiRequest(path, { ...options, method: "POST" }),
  put: (path, options = {}) => apiRequest(path, { ...options, method: "PUT" }),
  delete: (path, options = {}) => apiRequest(path, { ...options, method: "DELETE" }),
  upload: (path, fileOrFormData, options = {}) => {
    const formData = fileOrFormData instanceof FormData ? fileOrFormData : new FormData();
    if (!(fileOrFormData instanceof FormData)) {
      formData.append("file", fileOrFormData);
    }
    return apiRequest(path, { ...options, method: "POST", body: formData });
  },
  setToken,
  getToken,
  clearToken,
};

export const api = {
  login: async (credentials) => {
    const result = await apiClient.post("/login", { body: credentials, auth: false });
    if (result?.token) {
      setToken(result.token);
    }
    return result;
  },
  logout: () => clearToken(),
  getTables: (date) => apiClient.get("/tables", { params: date ? { date } : undefined }),
  createTable: (payload) => apiClient.post("/tables/add", { body: payload }),
  deleteTable: (id) => apiClient.delete(`/tables/delete/${id}`),
  getSettings: () => apiClient.get("/settings"),
  updateSettings: (payload) => apiClient.post("/settings/add", { body: payload }),
  updateProfile: (payload) => apiClient.put("/users/me", { body: payload }),
  uploadFile: (fileOrFormData) => apiClient.upload("/upload", fileOrFormData),
};

export { API_BASE_URL, setToken, getToken, clearToken };
