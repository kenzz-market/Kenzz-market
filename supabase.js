// ===============================
// KENZZ STORE SUPABASE CONFIG
// ===============================

const SUPABASE_URL = "https://uvcmkwwczsrjzsujomjb.supabase.co";

const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Y21rd3djenNyanpzdWpvbWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwODQ2NTIsImV4cCI6MjEwNjY2MDY1Mn0._nfIRL4z_L4VQPfgANkQkcf01Qos8qvBke1_A4ifwaM";


// ===============================
// AMBIL SEMUA PRODUK
// ===============================

async function getProducts(){

    const response = await fetch(
        `${SUPABASE_URL}/rest/v1/products?select=*`,
        {
            method:"GET",
            headers:{
                apikey:SUPABASE_KEY,
                Authorization:`Bearer ${SUPABASE_KEY}`
            }
        }
    );


    if(!response.ok){
        throw new Error(await response.text());
    }


    return await response.json();
}



// ===============================
// TAMBAH PRODUK (ADMIN)
// ===============================

async function addProduct(data){

    const response = await fetch(
        `${SUPABASE_URL}/rest/v1/products`,
        {
            method:"POST",

            headers:{
                apikey:SUPABASE_KEY,
                Authorization:`Bearer ${SUPABASE_KEY}`,
                "Content-Type":"application/json",
                Prefer:"return=representation"
            },

            body:JSON.stringify(data)
        }
    );


    if(!response.ok){
        throw new Error(await response.text());
    }


    return await response.json();
}




// ===============================
// HAPUS PRODUK (ADMIN)
// ===============================

async function deleteProduct(id){

    const response = await fetch(
        `${SUPABASE_URL}/rest/v1/products?id=eq.${id}`,
        {
            method:"DELETE",

            headers:{
                apikey:SUPABASE_KEY,
                Authorization:`Bearer ${SUPABASE_KEY}`
            }
        }
    );


    if(!response.ok){
        throw new Error(await response.text());
    }


    return true;
}




// ===============================
// CEK ADMIN / OWNER
// ===============================

async function checkAdmin(email){

    const response = await fetch(
        `${SUPABASE_URL}/rest/v1/admins?email=eq.${email}`,
        {
            method:"GET",

            headers:{
                apikey:SUPABASE_KEY,
                Authorization:`Bearer ${SUPABASE_KEY}`
            }
        }
    );


    if(!response.ok){
        return false;
    }


    const data = await response.json();


    return data.length > 0;
}



// ===============================
// EXPORT GLOBAL
// ===============================

window.getProducts = getProducts;
window.addProduct = addProduct;
window.deleteProduct = deleteProduct;
window.checkAdmin = checkAdmin;
