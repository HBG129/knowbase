import { Lang, TranslationKey, TranslationValues, t } from "@/lib/i18n";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

function localizedMessage(key: TranslationKey, values?: TranslationValues): string {
  const lang: Lang = typeof window !== "undefined" && localStorage.getItem("knowbase-lang") === "en" ? "en" : "zh";
  return t(lang, key, values);
}

function localizeApiDetail(detail: unknown): string {
  if (typeof detail !== "string" || !detail) return localizedMessage("api.requestFailed");

  const exactMessages: Record<string, TranslationKey> = {
    "Access denied": "api.accessDenied",
    "Not found": "api.notFound",
    "Email already registered": "api.emailRegistered",
    "Username already taken": "api.usernameTaken",
    "Invalid email or password": "api.invalidCredentials",
    "Account is deactivated": "api.accountDeactivated",
    "Invalid or expired token": "api.invalidToken",
    "User not found or inactive": "api.userInactive",
    "File is empty": "api.fileEmpty",
    "Document not found": "api.documentNotFound",
    "Conversation not found": "api.conversationNotFound",
    "CSV dataset not found": "api.datasetNotFound",
    "Question cannot be empty": "api.questionEmpty",
    "Message cannot be empty": "api.messageEmpty",
    "Configure an API key in Settings before running analysis": "api.analysisKeyRequired",
  };
  const exactKey = exactMessages[detail];
  if (exactKey) return localizedMessage(exactKey);

  const unsupportedType = detail.match(/^Unsupported file type:\s*(.+)$/);
  if (unsupportedType) return localizedMessage("api.unsupportedFileType", { type: unsupportedType[1] });
  const sizeLimit = detail.match(/^File exceeds\s+(\d+)MB limit$/);
  if (sizeLimit) return localizedMessage("api.fileTooLarge", { limit: sizeLimit[1] });
  const ingestionFailure = detail.match(/^Document ingestion failed:\s*(.+)$/);
  if (ingestionFailure) return localizedMessage("api.ingestionFailed", { message: ingestionFailure[1] });

  return detail;
}

async function fetchWithNetworkMessage(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  try {
    return await fetch(input, init);
  } catch (error) {
    throw new Error(localizedMessage("api.networkError"));
  }
}

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const token = typeof window !== "undefined"
    ? localStorage.getItem("access_token")
    : null;
  const res = await fetchWithNetworkMessage(BASE_URL + path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: "Bearer " + token } : {}),
      ...options?.headers,
    },
  });
  const text = await res.text();
  if (!res.ok) {
    const err = text
      ? (() => {
          try {
            return JSON.parse(text);
          } catch {
            return { detail: text };
          }
        })()
      : { detail: localizedMessage("api.requestFailed") };
    throw new Error(err.detail ? localizeApiDetail(err.detail) : "HTTP " + res.status);
  }
  if (res.status === 204 || !text) {
    return undefined as T;
  }
  return JSON.parse(text) as T;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "POST", body: body ? JSON.stringify(body) : undefined }),
  put: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PUT", body: body ? JSON.stringify(body) : undefined }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PATCH", body: body ? JSON.stringify(body) : undefined }),
};

export async function apiPostForm<T>(path: string, formData: FormData): Promise<T> {
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
  const res = await fetchWithNetworkMessage(BASE_URL + path, {
    method: "POST",
    headers: token ? { Authorization: "Bearer " + token } : {},
    body: formData,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: localizedMessage("api.uploadFailed") }));
    throw new Error(err.detail ? localizeApiDetail(err.detail) : "HTTP " + res.status);
  }
  return res.json();
}

/** SSE streaming - returns raw Response for ReadableStream consumption */
export function apiStream(path: string, body: unknown, signal?: AbortSignal): Promise<Response> {
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
  return fetchWithNetworkMessage(BASE_URL + path, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: "Bearer " + token } : {}),
    },
    body: JSON.stringify(body),
    signal,
  });
}
