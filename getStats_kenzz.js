// =====================================
// KENZZ STORE STATISTIK AUTO
// =====================================


async function getStats(){


    const { count: products, error } =

    await supabaseClient

    .from("products")

    .select("*", {

        count:"exact",

        head:true

    });



    if(error){

        console.log(
            "STAT ERROR:",
            error
        );


        return {

            products:0,

            member:0,

            uptime:"99%"

        };

    }



    return {

        products: products || 0,

        member: 0,

        uptime: "99%"

    };


}



// EXPORT GLOBAL

window.getStats = getStats;
