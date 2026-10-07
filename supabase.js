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

    const {data,error} =
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
    localStorage.removeItem("kenzz_role");
    location.href = "login.html";
}

async function logoutMember(){
    await supabaseClient.auth.signOut();
    localStorage.removeItem("kenzz_role");
    location.href = "member-login.html";
}



// =====================================
// CEK ROLE OWNER / ADMIN
// =====================================


async function checkRole(){


    const {data:userData}
    =
    await supabaseClient.auth.getUser();


    if(!userData.user){

        return null;

    }


    const {data,error}
    =
    await supabaseClient

    .from("admins")

    .select("*")

    .eq(
        "user_id",
        userData.user.id
    );


    if(error){

        console.log(error);

    }


    return data?.[0]?.role || null;

}



// =====================================
// PRODUK
// =====================================


async function getProducts(){


    const {data,error}
    =
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

        console.log(
            "GET PRODUCT ERROR:",
            error
        );

        throw error;

    }


    return data || [];

}




async function addProduct(product){


    const {data,error}
    =
    await supabaseClient

    .from("products")

    .insert([
        product
    ])

    .select();



    if(error){

        console.log(
            "ADD PRODUCT ERROR:",
            error
        );

        throw error;

    }


    return data;

}





async function updateProduct(id,product){


    const {data,error}
    =
    await supabaseClient

    .from("products")

    .update(product)

    .eq(
        "id",
        id
    )

    .select();



    if(error){

        throw error;

    }


    return data;

}




async function deleteProduct(id){


    const {data,error}
    =
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
window.logoutMember =
logoutMember;


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


// =====================================
// KENZZ STORE MEMBER SYSTEM
// =====================================

function normalizePhone(phone){
    let value = String(phone || "").trim().replace(/[\s()-]/g, "");
    if(value.startsWith("08")) value = "+62" + value.slice(1);
    else if(value.startsWith("62")) value = "+" + value;
    return value;
}

function isPhoneIdentifier(value){
    const v = String(value || "").trim();
    return !v.includes("@");
}

async function getMemberCount(){
    const { data, error } = await supabaseClient.rpc("get_member_count");
    if(error){
        console.error("MEMBER COUNT ERROR:", error);
        return 0;
    }
    return Number(data || 0);
}

async function getCurrentUser(){
    const { data, error } = await supabaseClient.auth.getUser();
    if(error || !data?.user) return null;
    return data.user;
}

async function getMemberProfile(){
    const user = await getCurrentUser();
    if(!user) return null;

    const { data, error } = await supabaseClient
        .from("members")
        .select("*")
        .eq("user_id", user.id)
        .maybeSingle();

    if(error) throw error;
    return data || null;
}

async function ensureMemberProfile(){
    const user = await getCurrentUser();
    if(!user) return null;

    const existing = await getMemberProfile();
    if(existing) return existing;

    const meta = user.user_metadata || {};
    const provider = user.app_metadata?.provider || (user.phone ? "phone" : "email");
    const payload = {
        user_id: user.id,
        name: meta.name || meta.full_name || meta.display_name || "",
        email: user.email || null,
        phone: user.phone || meta.phone || null,
        provider
    };

    const { data, error } = await supabaseClient
        .from("members")
        .upsert(payload, { onConflict:"user_id" })
        .select()
        .single();

    if(error) throw error;
    return data;
}

async function updateMember(userId, member){
    const { data, error } = await supabaseClient
        .from("members")
        .update(member)
        .eq("user_id", userId)
        .select()
        .single();

    if(error) throw error;
    return data;
}

async function signUpMember({ email="", phone="", password, name="" }){
    const normalizedPhone = normalizePhone(phone);
    const options = {
        data: {
            name: name || "",
            phone: normalizedPhone || ""
        }
    };

    let data, error;

    if(email){
        ({ data, error } = await supabaseClient.auth.signUp({
            email,
            password,
            options
        }));
    }else if(normalizedPhone){
        ({ data, error } = await supabaseClient.auth.signUp({
            phone: normalizedPhone,
            password,
            options
        }));
    }else{
        throw new Error("Masukkan email atau nomor telepon.");
    }

    if(error) throw error;
    return data;
}

async function loginMember(identifier, password){
    const value = String(identifier || "").trim();
    if(!value || !password) throw new Error("Email/nomor telepon dan password wajib diisi.");

    let data, error;
    if(isPhoneIdentifier(value)){
        ({ data, error } = await supabaseClient.auth.signInWithPassword({
            phone: normalizePhone(value),
            password
        }));
    }else{
        ({ data, error } = await supabaseClient.auth.signInWithPassword({
            email: value,
            password
        }));
    }

    if(error) throw error;
    await ensureMemberProfile();
    return data;
}

async function signInGoogle(){
    const { data, error } = await supabaseClient.auth.signInWithOAuth({
        provider: "google",
        options: {
            redirectTo: window.location.origin + "/index.html"
        }
    });
    if(error) throw error;
    return data;
}

async function sendPhoneOtp(phone){
    const normalizedPhone = normalizePhone(phone);
    if(!normalizedPhone) throw new Error("Nomor telepon wajib diisi.");
    const { data, error } = await supabaseClient.auth.signInWithOtp({ phone: normalizedPhone });
    if(error) throw error;
    return data;
}

async function verifyPhoneOtp(phone, token){
    const normalizedPhone = normalizePhone(phone);
    const { data, error } = await supabaseClient.auth.verifyOtp({
        phone: normalizedPhone,
        token,
        type: "sms"
    });
    if(error) throw error;
    await ensureMemberProfile();
    return data;
}

async function getMembers(){
    const role = await checkRole();
    if(role !== "owner") throw new Error("Akses hanya untuk owner.");

    const { data, error } = await supabaseClient
        .from("members")
        .select("*")
        .order("created_at", { ascending:false });

    if(error) throw error;
    return data || [];
}

async function getOwnerNotifications(unreadOnly=true){
    const role = await checkRole();
    if(role !== "owner") throw new Error("Akses hanya untuk owner.");

    let query = supabaseClient
        .from("notifications")
        .select("*")
        .order("created_at", { ascending:false });

    if(unreadOnly) query = query.eq("is_read", false);

    const { data, error } = await query;
    if(error) throw error;
    return data || [];
}

async function getAllOwnerNotifications(){
    return getOwnerNotifications(false);
}

async function markNotificationAsRead(id){
    const { error } = await supabaseClient
        .from("notifications")
        .update({ is_read:true })
        .eq("id", id);
    if(error) throw error;
    return true;
}

async function markAllNotificationsAsRead(){
    const { error } = await supabaseClient
        .from("notifications")
        .update({ is_read:true })
        .eq("is_read", false);
    if(error) throw error;
    return true;
}

window.getMemberCount = getMemberCount;
window.getCurrentUser = getCurrentUser;
window.getMemberProfile = getMemberProfile;
window.ensureMemberProfile = ensureMemberProfile;
window.updateMember = updateMember;
window.signUpMember = signUpMember;
window.loginMember = loginMember;
window.signInGoogle = signInGoogle;
window.sendPhoneOtp = sendPhoneOtp;
window.verifyPhoneOtp = verifyPhoneOtp;
window.getMembers = getMembers;
window.getOwnerNotifications = getOwnerNotifications;
window.getAllOwnerNotifications = getAllOwnerNotifications;
window.markNotificationAsRead = markNotificationAsRead;
window.markAllNotificationsAsRead = markAllNotificationsAsRead;
