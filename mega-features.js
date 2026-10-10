/* KENZZ STORE MEGA FEATURES - additive layer */
(function(){
  const money=n=>'Rp '+Number(n||0).toLocaleString('id-ID');
  window.KenzzMega={
    money,
    async reviews(productId){const {data,error}=await supabaseClient.from('product_reviews').select('id,product_id,rating,review,created_at,updated_at').eq('product_id',String(productId)).order('created_at',{ascending:false});if(error)throw error;return data||[]},
    async rating(productId){const rows=await this.reviews(productId);const avg=rows.length?rows.reduce((a,b)=>a+Number(b.rating||0),0)/rows.length:0;return {avg,count:rows.length}},
    async saveReview(productId,rating,review){const u=await getCurrentUser();if(!u)throw new Error('Login member diperlukan untuk memberi ulasan.');const {data,error}=await supabaseClient.from('product_reviews').upsert({product_id:String(productId),user_id:u.id,rating:Number(rating),review:String(review||'').trim(),updated_at:new Date().toISOString()},{onConflict:'product_id,user_id'}).select().single();if(error)throw error;return data},
    async referralCode(){const {data,error}=await supabaseClient.rpc('ensure_member_referral_code');if(error)throw error;return data},
    async applyReferral(code){const {data,error}=await supabaseClient.rpc('apply_referral',{p_code:String(code||'')});if(error)throw error;return data===true},
    async analytics(){const {data,error}=await supabaseClient.rpc('get_store_analytics');if(error)throw error;return data||{}},
    async categories(){const {data,error}=await supabaseClient.from('product_categories').select('*').order('name');if(error)throw error;return data||[]},
    async flashSales(){const {data,error}=await supabaseClient.from('flash_sales').select('*').eq('is_active',true).lte('starts_at',new Date().toISOString()).gt('expires_at',new Date().toISOString()).order('expires_at');if(error)throw error;return data||[]},
    async announcements(){const {data,error}=await supabaseClient.from('store_announcements').select('*').eq('is_active',true).lte('starts_at',new Date().toISOString()).or('expires_at.is.null,expires_at.gt.'+new Date().toISOString()).order('created_at',{ascending:false});if(error)throw error;return data||[]},
    realtime(){try{if(window.__kenzzRealtime)return;window.__kenzzRealtime=supabaseClient.channel('kenzz-live').on('postgres_changes',{event:'*',schema:'public',table:'purchase_history'},()=>location.pathname.endsWith('owner.html')&&window.loadOrders?.()).on('postgres_changes',{event:'*',schema:'public',table:'notifications'},()=>window.loadNotifications?.(false)).on('postgres_changes',{event:'*',schema:'public',table:'products'},()=>window.loadOwnerData?.()).on('postgres_changes',{event:'*',schema:'public',table:'product_reviews'},()=>window.renderKenzzReviews?.()).subscribe()}catch(e){console.warn('Realtime:',e)}}
  };
  document.addEventListener('DOMContentLoaded',()=>{KenzzMega.realtime(); if(location.pathname.endsWith('index.html')||location.pathname==='/'){KenzzMega.announcements().then(rows=>{const box=document.querySelector('.announcement');if(rows[0]&&box){box.querySelector('h2')&&(box.querySelector('h2').textContent='📢 '+rows[0].title);const p=box.querySelector('p');if(p)p.textContent=rows[0].message||'Update terbaru Kenzz Store.';if(rows[0].image_url){const safeImage=safeHttpUrl(rows[0].image_url,'');if(safeImage)box.style.backgroundImage=`linear-gradient(#0008,#0008),url("${safeImage.replace(/"/g,'%22')}")`}}}).catch(()=>{});
    KenzzMega.flashSales().then(async rows=>{if(!rows.length)return;const products=await getProducts();const hit=rows.map(s=>({...s,p:products.find(p=>String(p.id)===String(s.product_id))})).filter(x=>x.p);if(!hit.length)return;let sec=document.createElement('div');sec.className='card mega-flash';sec.innerHTML='<h2>⚡ Flash Sale</h2>'+hit.slice(0,4).map(x=>`<p><b>${escHtml(x.p.name)}</b> · ${money(x.sale_price)} · stok ${Number(x.stock||0)}</p>`).join('');document.querySelector('.container')?.appendChild(sec)}).catch(()=>{});
  }});
})();
