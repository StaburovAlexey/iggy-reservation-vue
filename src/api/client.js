const API_BASE_URL = (import.meta.env.VITE_APP_API || "").trim();

if (!API_BASE_URL) {
  console.warn("VITE_APP_API is not set. API requests will fail until it is provided.");
}

const now = () => (typeof performance !== "undefined" && performance.now ? performance.now() : Date.now());

const buildUrl = (path = "", params = {}) => {
  if (!API_BASE_URL) {
    throw new Error("API base URL is missing. Set VITE_APP_API in your environment.");
  }

  const url = new URL(path, API_BASE_URL);
  Object.entries(params)
    .filter(([, value]) => value !== undefined && value !== null)
    .forEach(([key, value]) => url.searchParams.append(key, value));

  return url;
};

export const apiRequest = async (path, options = {}) => {
  const { method = "GET", params, body, headers } = options;
  const url = buildUrl(path, params);
  const startedAt = now();

  const requestInit = {
    method,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  };

  console.info("[API] ->", method, url.toString(), { params, body });

  try {
    const response = await fetch(url, requestInit);
    const duration = Math.round(now() - startedAt);
    const contentType = response.headers.get("content-type") || "";
    const isJson = contentType.includes("application/json");
    const payload = isJson ? await response.json() : await response.text();

    console.info("[API] <-", method, url.toString(), response.status, `${duration}ms`);

    if (!response.ok) {
      const error = new Error(`API request failed with status ${response.status}`);
      error.status = response.status;
      error.response = payload;
      throw error;
    }

    return payload;
  } catch (error) {
    const duration = Math.round(now() - startedAt);
    console.error("[API] x", method, url.toString(), `${duration}ms`, error);
    throw error;
  }
};

export { API_BASE_URL };
