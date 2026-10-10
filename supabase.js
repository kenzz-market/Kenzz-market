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

function escHtml(value){return String(value ?? '').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));}
function safeHttpUrl(value,fallback=''){try{const u=new URL(String(value||''),window.location.href);if(u.protocol==='http:'||u.protocol==='https:')return u.href;}catch(e){}return fallback;}
window.escHtml=escHtml; window.safeHttpUrl=safeHttpUrl;



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
// KATALOG PRODUK PROMO
// =====================================

async function getPromoProducts(){
    const {data,error}=await supabaseClient
        .from('promo_products')
        .select('*')
        .eq('is_active', true)
        .gt('expires_at', new Date().toISOString())
        .order('created_at',{ascending:false});
    if(error) throw error;
    return data || [];
}

async function addPromoProduct(promo){
    const {data,error}=await supabaseClient
        .from('promo_products')
        .insert([promo])
        .select();
    if(error) throw error;
    return data;
}

async function updatePromoProduct(id,promo){
    const {data,error}=await supabaseClient
        .from('promo_products')
        .update(promo)
        .eq('id',id)
        .select();
    if(error) throw error;
    return data;
}

async function deletePromoProduct(id){
    const {data,error}=await supabaseClient
        .from('promo_products')
        .delete()
        .eq('id',id);
    if(error) throw error;
    return data;
}

window.getPromoProducts=getPromoProducts;
window.addPromoProduct=addPromoProduct;
window.updatePromoProduct=updatePromoProduct;
window.deletePromoProduct=deletePromoProduct;
window.decrementPromoStock=decrementPromoStock;

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
// OWNER MANAGEMENT
// =====================================

async function getAdmins(){
    const role=await checkRole();
    if(role!=="owner") throw new Error("Akses hanya untuk owner.");
    const {data,error}=await supabaseClient.rpc("owner_list_admins");
    if(error) throw error;
    return data || [];
}

async function addAdminByEmail(email){
    const role=await checkRole();
    if(role!=="owner") throw new Error("Akses hanya untuk owner.");
    const {data,error}=await supabaseClient.rpc("owner_add_admin_by_email",{p_email:email});
    if(error) throw error;
    return data;
}

async function deleteAdmin(userId){
    const role=await checkRole();
    if(role!=="owner") throw new Error("Akses hanya untuk owner.");
    const {data,error}=await supabaseClient.rpc("owner_delete_admin",{p_user_id:userId});
    if(error) throw error;
    return data;
}

async function deleteMember(userId){
    const role=await checkRole();
    if(role!=="owner") throw new Error("Akses hanya untuk owner.");
    const {data,error}=await supabaseClient.rpc("owner_delete_member",{p_user_id:userId});
    if(error) throw error;
    return data;
}

window.getAdmins=getAdmins;
window.addAdminByEmail=addAdminByEmail;
window.deleteAdmin=deleteAdmin;
window.deleteMember=deleteMember;

// =====================================
// MEMBER PURCHASE / ATOMIC CHECKOUT
// =====================================
async function requireMemberForPurchase(purchaseData){const user=await getCurrentUser();if(user)return true;localStorage.setItem('kenzz_pending_purchase',JSON.stringify({...purchaseData,created_at:Date.now()}));location.href='register.html?return=purchase';return false;}
function getPendingPurchase(){try{const raw=localStorage.getItem('kenzz_pending_purchase');if(!raw)return null;const data=JSON.parse(raw);if(!data||!data.created_at||Date.now()-Number(data.created_at)>24*60*60*1000){localStorage.removeItem('kenzz_pending_purchase');return null;}return data;}catch(e){localStorage.removeItem('kenzz_pending_purchase');return null;}}
function clearPendingPurchase(){localStorage.removeItem('kenzz_pending_purchase');}
function cleanPurchaseItems(items=[]){return (Array.isArray(items)?items:[]).map(p=>({id:String(p?.id??'').trim(),type:['product','promo','flash'].includes(String(p?.type||'').toLowerCase())?String(p.type).toLowerCase():'product',qty:Math.floor(Number(p?.qty??1))})).filter(p=>p.id&&Number.isFinite(p.qty)&&p.qty>=1&&p.qty<=1000);}
async function createPurchaseOrder(items=[],voucherCode=null){const clean=cleanPurchaseItems(items);if(!clean.length)throw new Error('Produk pembelian tidak valid.');if(clean.length>50)throw new Error('Maksimal 50 baris produk per pesanan.');const {data,error}=await supabaseClient.rpc('create_purchase_order',{p_items:clean,p_voucher_code:voucherCode?String(voucherCode).trim():null});if(error)throw error;if(!data?.success)throw new Error('Checkout gagal.');return data;}
async function createFlashOrder(flashId,qty=1){return createPurchaseOrder([{id:String(flashId),type:'flash',qty:Math.floor(Number(qty||1))}],null);}
function buildWhatsAppOrderUrl(order){const items=Array.isArray(order?.items)?order.items:[];let lines=[`Halo ${STORE_SETTINGS.storeName},`,'','Saya ingin membeli produk berikut:',''];items.forEach(p=>{const qty=Math.max(1,Number(p.qty||1));lines.push(`${p.name||'Produk'}\nJumlah: ${qty}\nHarga: Rp ${(Number(p.price||0)*qty).toLocaleString('id-ID')}\n`);});lines.push(`Subtotal: Rp ${Number(order?.subtotal??order?.total??0).toLocaleString('id-ID')}`);if(Number(order?.discount||0)>0)lines.push(`Diskon: Rp ${Number(order.discount).toLocaleString('id-ID')}${order.voucher_code?' ('+order.voucher_code+')':''}`);lines.push(`Total: Rp ${Number(order?.total||0).toLocaleString('id-ID')}`,'','Mohon bantu cek ketersediaan.','','Terima kasih.');return 'https://wa.me/'+String(STORE_SETTINGS.whatsappOwner||'').replace(/[^0-9]/g,'')+'?text='+encodeURIComponent(lines.join('\n'));}
function buildWhatsAppPurchaseUrl(purchaseData){const qty=Math.max(1,Number(purchaseData?.qty||1));return buildWhatsAppOrderUrl({items:[{name:purchaseData?.name||'Produk',price:Number(purchaseData?.price||0),qty}],subtotal:Number(purchaseData?.price||0)*qty,total:Number(purchaseData?.price||0)*qty,discount:0});}
function openWhatsAppPurchase(purchaseData){clearPendingPurchase();window.location.href=buildWhatsAppPurchaseUrl(purchaseData);}
async function resumePendingPurchase(){const pending=getPendingPurchase();if(!pending)return false;if(!(await getCurrentUser()))return false;let items=pending.items;if(!items&&pending.id)items=[{id:String(pending.id),type:pending.type==='promo'?'promo':pending.type==='flash'?'flash':'product',qty:pending.qty||1}];try{const order=await createPurchaseOrder(items,pending.voucherCode||null);clearPendingPurchase();window.location.href=buildWhatsAppOrderUrl(order);return true;}catch(e){console.error('RESUME PURCHASE:',e);clearPendingPurchase();alert('Checkout setelah login gagal: '+e.message);return false;}}
async function decrementProductStock(){throw new Error('Fungsi stok lama sudah dinonaktifkan. Gunakan checkout atomik.');}
async function decrementProductStocks(){throw new Error('Fungsi stok lama sudah dinonaktifkan. Gunakan checkout atomik.');}
async function decrementPromoStock(){throw new Error('Fungsi stok promo lama sudah dinonaktifkan. Gunakan checkout atomik.');}
window.requireMemberForPurchase=requireMemberForPurchase;window.getPendingPurchase=getPendingPurchase;window.clearPendingPurchase=clearPendingPurchase;window.cleanPurchaseItems=cleanPurchaseItems;window.createPurchaseOrder=createPurchaseOrder;window.createFlashOrder=createFlashOrder;window.resumePendingPurchase=resumePendingPurchase;window.buildWhatsAppOrderUrl=buildWhatsAppOrderUrl;window.buildWhatsAppPurchaseUrl=buildWhatsAppPurchaseUrl;window.openWhatsAppPurchase=openWhatsAppPurchase;window.decrementProductStock=decrementProductStock;window.decrementProductStocks=decrementProductStocks;window.decrementPromoStock=decrementPromoStock;

// =====================================
// FAVORIT MEMBER + RIWAYAT PEMBELIAN
// =====================================

async function getFavorites(){
    const user=await getCurrentUser();
    if(!user) return [];
    const {data,error}=await supabaseClient.from('member_favorites').select('*').eq('user_id',user.id).order('created_at',{ascending:false});
    if(error) throw error;
    return data||[];
}

async function isFavorite(productId){
    const user=await getCurrentUser();
    if(!user) return false;
    const {data,error}=await supabaseClient.from('member_favorites').select('id').eq('user_id',user.id).eq('product_id',String(productId)).maybeSingle();
    if(error) throw error;
    return !!data;
}

async function toggleFavorite(product){
    const user=await getCurrentUser();
    if(!user){
        localStorage.setItem('kenzz_pending_favorite',JSON.stringify(product));
        location.href='register.html?return=favorite';
        return false;
    }
    const exists=await isFavorite(product.id);
    if(exists){
        const {error}=await supabaseClient.from('member_favorites').delete().eq('user_id',user.id).eq('product_id',String(product.id));
        if(error) throw error;
        return false;
    }
    const {error}=await supabaseClient.from('member_favorites').insert({user_id:user.id,product_id:String(product.id),product_name:product.name||'',product_price:Number(product.price||0),product_image:product.image||''});
    if(error) throw error;
    return true;
}

async function savePurchaseHistory(items,total,status='Menunggu konfirmasi',voucherCode=null,discount=0){return createPurchaseOrder(items,voucherCode);}

async function getPurchaseHistory(){
    const user=await getCurrentUser();
    if(!user) return [];
    const {data,error}=await supabaseClient.from('purchase_history').select('*').eq('user_id',user.id).order('created_at',{ascending:false});
    if(error) throw error;
    return data||[];
}

async function getOwnerPurchaseHistory(){
    const role=await checkRole();
    if(role!=='owner') throw new Error('Akses hanya untuk owner.');
    const {data,error}=await supabaseClient.from('purchase_history').select('*').order('created_at',{ascending:false}).limit(100);
    if(error) throw error;
    return data||[];
}

window.getFavorites=getFavorites;
window.isFavorite=isFavorite;
window.toggleFavorite=toggleFavorite;
window.savePurchaseHistory=savePurchaseHistory;
window.getPurchaseHistory=getPurchaseHistory;
window.getOwnerPurchaseHistory=getOwnerPurchaseHistory;

// =====================================
// KENZZ STORE: ORDER + VOUCHER UPGRADE
// =====================================
async function getActiveVouchers(){
  const {data,error}=await supabaseClient.from('vouchers').select('*').eq('is_active',true).order('created_at',{ascending:false});
  if(error) throw error; return data||[];
}
async function validateVoucher(code,total){
  const user=await getCurrentUser(); if(!user) throw new Error('Login member diperlukan.');
  const {data,error}=await supabaseClient.rpc('redeem_voucher',{p_code:String(code||''),p_total:Number(total||0)});
  if(error) throw error; return data;
}
async function incrementVoucherUsage(){throw new Error('Voucher usage sekarang diproses atomik saat checkout.');}
async function getOwnerVouchers(){const role=await checkRole();if(role!=='owner')throw new Error('Akses hanya untuk owner.');const {data,error}=await supabaseClient.from('vouchers').select('*').order('created_at',{ascending:false});if(error)throw error;return data||[];}
async function addVoucher(v){const role=await checkRole();if(role!=='owner')throw new Error('Akses hanya untuk owner.');const {data,error}=await supabaseClient.from('vouchers').insert([v]).select().single();if(error)throw error;return data;}
async function updateVoucher(id,v){const role=await checkRole();if(role!=='owner')throw new Error('Akses hanya untuk owner.');const {data,error}=await supabaseClient.from('vouchers').update(v).eq('id',id).select().single();if(error)throw error;return data;}
async function deleteVoucher(id){const role=await checkRole();if(role!=='owner')throw new Error('Akses hanya untuk owner.');const {error}=await supabaseClient.from('vouchers').delete().eq('id',id);if(error)throw error;return true;}
async function updatePurchaseStatus(id,status){const role=await checkRole();if(role!=='owner')throw new Error('Akses hanya untuk owner.');const {data,error}=await supabaseClient.rpc('update_purchase_status',{p_order_id:id,p_status:String(status)});if(error)throw error;return data;}
async function getMemberNotifications(){const user=await getCurrentUser();if(!user)return [];const {data,error}=await supabaseClient.from('notifications').select('*').eq('user_id',user.id).order('created_at',{ascending:false}).limit(50);if(error)throw error;return data||[];}
async function markMemberNotificationsRead(){const user=await getCurrentUser();if(!user)return;const {error}=await supabaseClient.from('notifications').update({is_read:true}).eq('user_id',user.id).eq('is_read',false);if(error)throw error;}
window.getActiveVouchers=getActiveVouchers;window.validateVoucher=validateVoucher;window.incrementVoucherUsage=incrementVoucherUsage;window.getOwnerVouchers=getOwnerVouchers;window.addVoucher=addVoucher;window.updateVoucher=updateVoucher;window.deleteVoucher=deleteVoucher;window.updatePurchaseStatus=updatePurchaseStatus;window.getMemberNotifications=getMemberNotifications;window.markMemberNotificationsRead=markMemberNotificationsRead;



// SESSION SAFETY: logout after 30 minutes of inactivity.
(function(){
 const KEY='kenzz_last_activity', LIMIT=30*60*1000;
 function touch(){localStorage.setItem(KEY,String(Date.now()));}
 ['click','keydown','touchstart','scroll'].forEach(e=>window.addEventListener(e,touch,{passive:true}));
 setInterval(async()=>{const t=Number(localStorage.getItem(KEY)||0);if(t&&Date.now()-t>LIMIT){localStorage.removeItem(KEY);try{await supabaseClient.auth.signOut()}catch(e){} location.href='login.html';}},60000); touch();
})();
