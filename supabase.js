// ===============================
// KENZZ STORE SUPABASE CONFIG
// ===============================

const SUPABASE_URL = "https://uvcmkwwczsrjzsujomjb.supabase.co";

const SUPABASE_KEY = "ISI_ANON_KEY_KAMU";


const supabaseClient = supabase.createClient(
    SUPABASE_URL,
    SUPABASE_KEY
);


// ===============================
// LOGIN EMAIL + PASSWORD
// ===============================

async function loginUser(email,password){

    const {data,error} =
    await supabaseClient.auth.signInWithPassword({

        email: email,
        password: password

    });


    if(error){
        throw error;
    }


    return data;

}



// ===============================
// LOGOUT
// ===============================

async function logoutUser(){

    await supabaseClient.auth.signOut();

    localStorage.removeItem("kenzz_role");

    window.location.href="login.html";

}



// ===============================
// CEK ROLE ADMIN / OWNER
// ===============================

async function checkRole(){


    const {
        data:{
            user
        }
    } =
    await supabaseClient.auth.getUser();



    if(!user){

        return null;

    }



    const {data,error}=

    await supabaseClient

    .from("admins")

    .select("role")

    .eq("user_id",user.id)

    .single();



    if(error){

        return null;

    }



    return data.role;


}



// ===============================
// PRODUK
// ===============================


async function getProducts(){


const {data,error}=

await supabaseClient

.from("products")

.select("*");


if(error){

throw error;

}


return data;


}




async function addProduct(product){


const {data,error}=

await supabaseClient

.from("products")

.insert(product);


if(error){

throw error;

}


return data;


}




async function deleteProduct(id){


const {data,error}=

await supabaseClient

.from("products")

.delete()

.eq("id",id);



if(error){

throw error;

}


return data;


}




window.loginUser=loginUser;
window.logoutUser=logoutUser;
window.checkRole=checkRole;

window.getProducts=getProducts;
window.addProduct=addProduct;
window.deleteProduct=deleteProduct;
