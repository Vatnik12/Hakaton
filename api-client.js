(() => {
  const api = async (path, options = {}) => {
    const response = await fetch(`/api/v1${path}`, {headers:{'Content-Type':'application/json',...(options.headers||{})},...options});
    if (!response.ok) throw new Error(`API ${response.status}`);
    return response.status === 204 ? null : response.json();
  };

  const addStyles = () => {
    if (document.querySelector('#backend-status-style')) return;
    const style=document.createElement('style');style.id='backend-status-style';style.textContent='.backend-status{position:fixed;right:18px;bottom:18px;z-index:90;padding:10px 14px;border-radius:999px;background:#183d32ee;color:#fff;font:700 12px Manrope,system-ui;box-shadow:0 12px 35px #183d3244;backdrop-filter:blur(12px)}.backend-status i{display:inline-block;width:8px;height:8px;border-radius:50%;background:#70e0ae;margin-right:7px;box-shadow:0 0 12px #70e0ae}@media(max-width:720px){.backend-status{font-size:10px;right:10px;bottom:10px}}';document.head.appendChild(style);
  };

  const renderStatus = async () => {
    try {
      const meta = await api('/meta');
      let badge=document.querySelector('.backend-status');
      if(!badge){badge=document.createElement('div');badge.className='backend-status';document.body.appendChild(badge);}
      badge.innerHTML=`<i></i> Java API · PostgreSQL 17 · ${meta.listings} квартир`;
      document.querySelectorAll('.menu b').forEach((item,index)=>{if(index===0)item.textContent=meta.listings;if(index===1)item.textContent=meta.profiles;});
    } catch(error){console.warn('Gnezdo API unavailable; frontend mock data remains active.',error);}
  };

  const connectOwnerForm = () => {
    const button=[...document.querySelectorAll('.modal .primary')].find(x=>x.textContent.includes('Опубликовать объявление'));
    if(!button||button.dataset.apiConnected)return;
    button.dataset.apiConnected='1';
    button.onclick=async()=>{
      const address=document.querySelector('#oa')?.value?.trim();
      const price=Number(document.querySelector('#op')?.value||0);
      const rooms=Number(document.querySelector('#or')?.value||1);
      const slots=Number(document.querySelector('#os')?.value||1);
      try {
        await api('/listings',{method:'POST',body:JSON.stringify({title:'Новое объявление в Гнезде',address,district:'Центральный',price,rooms,area:Math.max(30,rooms*22),slots,owner:'Дима',traits:['clean','long'],redFlags:[]})});
        closeModal();toast('Объявление сохранено в PostgreSQL');renderStatus();
      } catch(error){toast('Не удалось сохранить объявление через API');}
    };
  };

  addStyles();
  new MutationObserver(connectOwnerForm).observe(document.documentElement,{childList:true,subtree:true});
  window.addEventListener('DOMContentLoaded',renderStatus);
  setTimeout(renderStatus,600);
})();
