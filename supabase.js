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

async function signUpMember(email, password, name, phone){
    const { data, error } = await supabaseClient.auth.signUp({
        email,
        password,
        options: {
            data: {
                name: name || "",
                phone: phone || ""
            }
        }
    });

    if(error) throw error;
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
    const { data, error } = await supabaseClient.auth.signInWithOtp({
        phone
    });
    if(error) throw error;
    return data;
}

async function verifyPhoneOtp(phone, token){
    const { data, error } = await supabaseClient.auth.verifyOtp({
        phone,
        token,
        type: "sms"
    });
    if(error) throw error;
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
window.updateMember = updateMember;
window.signUpMember = signUpMember;
window.signInGoogle = signInGoogle;
window.sendPhoneOtp = sendPhoneOtp;
window.verifyPhoneOtp = verifyPhoneOtp;

async function loginMember(email,password){
    const {data,error}=await supabaseClient.auth.signInWithPassword({email,password});
    if(error) throw error;
    return data;
}
window.loginMember=loginMember;
window.getMembers = getMembers;
window.getOwnerNotifications = getOwnerNotifications;
window.markNotificationAsRead = markNotificationAsRead;
window.markAllNotificationsAsRead = markAllNotificationsAsRead;



async function logoutMember(){
    await supabaseClient.auth.signOut();
    localStorage.removeItem('kenzz_role');
    location.href='index.html';
}
window.logoutMember=logoutMember;

// =====================================
// MEMBER PURCHASE GATE
// =====================================

async function requireMemberForPurchase(purchaseData){
    const user = await getCurrentUser();
    if(user){
        return true;
    }

    localStorage.setItem('kenzz_pending_purchase', JSON.stringify({
        ...purchaseData,
        created_at: Date.now()
    }));

    location.href = 'register.html?return=purchase';
    return false;
}

function getPendingPurchase(){
    try{
        const raw = localStorage.getItem('kenzz_pending_purchase');
        return raw ? JSON.parse(raw) : null;
    }catch(e){
        return null;
    }
}

function clearPendingPurchase(){
    localStorage.removeItem('kenzz_pending_purchase');
}

async function decrementProductStock(productId, qty=1){
    const { data, error } = await supabaseClient.rpc('decrement_product_stock', {
        p_product_id: String(productId),
        p_qty: Math.max(1, Number(qty || 1))
    });
    if(error) throw error;
    return data === true;
}

async function decrementProductStocks(items=[]){
    const clean = (items || []).map(p => ({
        id: String(p.id),
        qty: Math.max(1, Number(p.qty || 1))
    })).filter(p => p.id && p.qty > 0);
    if(!clean.length) return true;
    const { data, error } = await supabaseClient.rpc('decrement_product_stocks', {
        p_items: clean
    });
    if(error) throw error;
    return data === true;
}

window.decrementProductStock = decrementProductStock;
window.decrementProductStocks = decrementProductStocks;

function buildWhatsAppPurchaseUrl(purchaseData){
    const lines = [
        `Halo ${STORE_SETTINGS.storeName},`,
        '',
        'Saya ingin membeli produk berikut:',
        '',
        `Produk: ${purchaseData.name || '-'}`,
        `Harga: Rp ${Number(purchaseData.price || 0).toLocaleString('id-ID')}`,
        purchaseData.qty ? `Jumlah: ${purchaseData.qty}` : '',
        '',
        'Mohon bantu cek ketersediaan dan pilihkan produk yang tersedia.',
        '',
        'Terima kasih.'
    ].filter(Boolean).join('\n');

    return 'https://wa.me/' + STORE_SETTINGS.whatsappOwner + '?text=' + encodeURIComponent(lines);
}

function openWhatsAppPurchase(purchaseData){
    clearPendingPurchase();
    window.location.href = buildWhatsAppPurchaseUrl(purchaseData);
}

window.requireMemberForPurchase = requireMemberForPurchase;
window.getPendingPurchase = getPendingPurchase;
window.clearPendingPurchase = clearPendingPurchase;
window.buildWhatsAppPurchaseUrl = buildWhatsAppPurchaseUrl;
window.openWhatsAppPurchase = openWhatsAppPurchase;
