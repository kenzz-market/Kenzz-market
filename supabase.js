const SUPABASE_URL = "https://uvcmkwwczsrjzsujomjb.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Y21rd3djenNyanpzdWpvbWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwODQ2NTIsImV4cCI6MjEwNjY2MDY1Mn0._nfIRL4z_L4VQPfgANkQkcf01Qos8qvBke1_A4ifwaM";

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
