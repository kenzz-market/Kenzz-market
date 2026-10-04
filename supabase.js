const SUPABASE_URL = "https://uvcmkwwczsrjzsujomjb.supabase.co";
const SUPABASE_KEY = "MASUKKAN_ANON_KEY_SUPABASE";

async function getProducts(){
 const r = await fetch(`${SUPABASE_URL}/rest/v1/products?select=*`, {
  headers:{apikey:SUPABASE_KEY, Authorization:`Bearer ${SUPABASE_KEY}`}
 });
 return await r.json();
}

async function addProduct(data){
 return fetch(`${SUPABASE_URL}/rest/v1/products`,{
  method:"POST",
  headers:{
   apikey:SUPABASE_KEY,
   Authorization:`Bearer ${SUPABASE_KEY}`,
   "Content-Type":"application/json"
  },
  body:JSON.stringify(data)
 });
}
