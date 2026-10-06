// =====================================
// KENZZ STORE SUPABASE SYSTEM
// =====================================

// URL & KEY SUPABASE
const SUPABASE_URL =
"https://uvcmkwwczsrjzsujomjb.supabase.co";


const SUPABASE_KEY =
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV2Y21rd3djenNyanpzdWpvbWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEwODQ2NTIsImV4cCI6MjEwNjY2MDY1Mn0._nfIRL4z_L4VQPfgANkQkcf01Qos8qvBke1_A4ifwaM";


const supabaseClient =
supabase.createClient(
    SUPABASE_URL,
    SUPABASE_KEY
);


// =====================================
// AUTH LOGIN
// =====================================


async function loginUser(email,password){

    const {
        data,
        error
    } =
    await supabaseClient.auth.signInWithPassword({

        email,
        password

    });


    if(error){

        throw error;

    }


    return data;

}



// =====================================
// LOGOUT
// =====================================


async function logoutUser(){

    await supabaseClient.auth.signOut();

    localStorage.removeItem(
        "kenzz_role"
    );


    location.href =
    "login.html";

}



// =====================================
// CEK ROLE OWNER / ADMIN
// =====================================


async function checkRole(){

const {data:userData}=await supabaseClient.auth.getUser();

console.log("USER LOGIN:",userData);

const {data,error}=await supabaseClient
.from("admins")
.select("*")
.eq("user_id",userData.user.id);

console.log("DATA ADMIN:",data);
console.log("ERROR:",error);

return data?.[0]?.role || null;
}



// =====================================
// PRODUK
// =====================================


async function getProducts(){


    const {
        data,
        error

    } =

    await supabaseClient

    .from("products")

    .select("*")

    .order(
        "created_at",
        {
            ascending:false
        }
    );



    if(error){

        throw error;

    }


    return data || [];

}




async function addProduct(product){


    const {
        data,
        error

    } =

    await supabaseClient

    .from("products")

    .insert(product);



    if(error){

        throw error;

    }


    return data;

}




async function updateProduct(id,product){


    const {
        data,
        error

    } =

    await supabaseClient

    .from("products")

    .update(product)

    .eq(
        "id",
        id
    );



    if(error){

        throw error;

    }


    return data;

}





async function deleteProduct(id){


    const {
        data,
        error

    } =

    await supabaseClient

    .from("products")

    .delete()

    .eq(
        "id",
        id
    );



    if(error){

        throw error;

    }


    return data;

}



// =====================================
// KERANJANG LOCAL STORAGE
// =====================================


function getCart(){

    return JSON.parse(

        localStorage.getItem(
            "kenzz_cart"
        )

    ) || [];

}



function saveCart(cart){

    localStorage.setItem(

        "kenzz_cart",

        JSON.stringify(cart)

    );

}




function addToCart(product){


    let cart =
    getCart();


    const exist =
    cart.find(
        item =>
        item.id === product.id
    );



    if(exist){

        exist.qty++;

    }else{

        cart.push({

            ...product,

            qty:1

        });

    }


    saveCart(cart);


}





function clearCart(){

    localStorage.removeItem(
        "kenzz_cart"
    );

}



// =====================================
// EXPORT GLOBAL
// =====================================


window.loginUser =
loginUser;


window.logoutUser =
logoutUser;


window.checkRole =
checkRole;


window.getProducts =
getProducts;


window.addProduct =
addProduct;


window.updateProduct =
updateProduct;


window.deleteProduct =
deleteProduct;


window.getCart =
getCart;


window.saveCart =
saveCart;


window.addToCart =
addToCart;


window.clearCart =
clearCart;
