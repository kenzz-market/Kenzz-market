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
// MEMBER SYSTEM
// =====================================

async function getMemberCount(){

    const {
        data,
        error
    } = await supabaseClient.rpc("get_member_count");

    if(error){
        console.error("Gagal mengambil jumlah member:", error);
        return 0;
    }

    return Number(data || 0);
}


async function getMemberProfile(){

    const {
        data: { user },
        error: userError
    } = await supabaseClient.auth.getUser();

    if(userError || !user){
        return null;
    }

    const {
        data,
        error
    } = await supabaseClient
        .from("members")
        .select("*")
        .eq("user_id", user.id)
        .maybeSingle();

    if(error){
        throw error;
    }

    return data || null;
}


async function createMember(member){

    const {
        data,
        error
    } = await supabaseClient
        .from("members")
        .insert(member)
        .select()
        .single();

    if(error){
        throw error;
    }

    return data;
}


async function updateMember(userId, member){

    const {
        data,
        error
    } = await supabaseClient
        .from("members")
        .update(member)
        .eq("user_id", userId)
        .select()
        .single();

    if(error){
        throw error;
    }

    return data;
}


// =====================================
// OWNER NOTIFICATIONS
// =====================================

async function getOwnerNotifications(){

    const {
        data,
        error
    } = await supabaseClient
        .from("notifications")
        .select("*")
        .eq("is_read", false)
        .order("created_at", { ascending:false });

    if(error){
        console.error("Gagal mengambil notifikasi:", error);
        return [];
    }

    return data || [];
}


async function getAllOwnerNotifications(){

    const {
        data,
        error
    } = await supabaseClient
        .from("notifications")
        .select("*")
        .order("created_at", { ascending:false });

    if(error){
        console.error("Gagal mengambil semua notifikasi:", error);
        return [];
    }

    return data || [];
}


async function markNotificationAsRead(id){

    const {
        error
    } = await supabaseClient
        .from("notifications")
        .update({ is_read:true })
        .eq("id", id);

    if(error){
        throw error;
    }

    return true;
}


async function markAllNotificationsAsRead(){

    const {
        error
    } = await supabaseClient
        .from("notifications")
        .update({ is_read:true })
        .eq("is_read", false);

    if(error){
        throw error;
    }

    return true;
}


// =====================================
// MEMBER LIST FOR OWNER
// =====================================

async function getMembers(){

    const {
        data,
        error
    } = await supabaseClient
        .from("members")
        .select("*")
        .order("created_at", { ascending:false });

    if(error){
        throw error;
    }

    return data || [];
}


// =====================================
// EXPORT MEMBER SYSTEM
// =====================================

window.getMemberCount = getMemberCount;
window.getMemberProfile = getMemberProfile;
window.createMember = createMember;
window.updateMember = updateMember;

window.getOwnerNotifications = getOwnerNotifications;
window.getAllOwnerNotifications = getAllOwnerNotifications;
window.markNotificationAsRead = markNotificationAsRead;
window.markAllNotificationsAsRead = markAllNotificationsAsRead;

window.getMembers = getMembers;

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
