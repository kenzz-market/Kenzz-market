const SUPABASE_URL = "https://uvcmkwwczsrjzsujomjb.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Y21rd3djenNyanpzdWpvbWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwODQ2NTIsImV4cCI6MjEwNjY2MDY1Mn0._nfIRL4z_L4VQPfgANkQkcf01Qos8qvBke1_A4ifwaM";

const headers = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  "Content-Type": "application/json"
};

async function supabaseRequest(path, options = {}) {
  const response = await fetch(`${SUPABASE_URL}${path}`, {
    ...options,
    headers: {
      ...headers,
      ...(options.headers || {})
    }
  });

  const text = await response.text();
  let data = null;

  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }

  if (!response.ok) {
    const message =
      (data &&
        typeof data === "object" &&
        (data.message || data.error_description || data.hint)) ||
      `Supabase request gagal (${response.status})`;

    throw new Error(message);
  }

  return data;
}

async function getProducts() {
  return supabaseRequest("/rest/v1/products?select=*&order=id.desc");
}

async function addProduct(data) {
  return supabaseRequest("/rest/v1/products", {
    method: "POST",
    headers: {
      Prefer: "return=representation"
    },
    body: JSON.stringify(data)
  });
}

async function deleteProduct(id) {
  if (id === undefined || id === null || id === "") {
    throw new Error("ID produk tidak valid.");
  }

  return supabaseRequest(
    `/rest/v1/products?id=eq.${encodeURIComponent(id)}`,
    {
      method: "DELETE",
      headers: {
        Prefer: "return=representation"
      }
    }
  );
}
