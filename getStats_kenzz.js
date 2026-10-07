// =====================================
// KENZZ STORE STATISTIK AUTO
// =====================================

async function getStats(){
    let products = 0;
    let member = 0;

    const productResult = await supabaseClient
        .from("products")
        .select("*", { count:"exact", head:true });

    if(!productResult.error) products = productResult.count || 0;

    if(typeof getMemberCount === "function"){
        member = await getMemberCount();
    }

    return {
        products,
        member,
        uptime:"99%"
    };
}

window.getStats = getStats;
