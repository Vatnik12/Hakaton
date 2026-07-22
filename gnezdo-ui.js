(() => {
  'use strict';

  const LOGO = '/assets/gnezdo-logo.png';
  const MEMORY_KEY = 'gnezdo-chat-memory-v2';
  let activeChatId = null;
  let introStarted = false;

  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => [...root.querySelectorAll(s)];
  const normalize = value => String(value || '').toLowerCase().replace(/ё/g, 'е').replace(/[–—]/g, '-').replace(/[^a-zа-я0-9@.+\-\s]/gi, ' ').replace(/\s+/g, ' ').trim();
  const choice = (arr, seed = Date.now()) => arr[Math.abs(seed) % arr.length];
  const loadMemory = () => { try { return JSON.parse(localStorage.getItem(MEMORY_KEY) || '{}'); } catch { return {}; } };
  const memoryStore = loadMemory();
  const saveMemory = () => localStorage.setItem(MEMORY_KEY, JSON.stringify(memoryStore));

  function introMarkup() {
    return `<div class="gnezdo-intro" id="gnezdoIntro" aria-label="Загрузка Гнезда">
      <div class="intro-panel intro-panel-left"></div><div class="intro-panel intro-panel-right"></div><div class="intro-grain"></div>
      <div class="intro-stage"><div class="intro-logo-orbit"><span class="intro-ring intro-ring-one"></span><span class="intro-ring intro-ring-two"></span><img class="intro-logo" src="${LOGO}" alt="Логотип Гнездо"></div><div class="intro-wordmark">Гнездо</div><div class="intro-caption">найди своих · найди своё место</div></div>
      <div class="intro-flight" aria-hidden="true"><svg viewBox="0 0 120 60"><path d="M4 38 C20 16 38 15 57 31 C72 14 92 12 116 30"/><path d="M57 31 C58 39 64 43 75 44"/></svg></div><div class="intro-diagonal"></div>
    </div>`;
  }

  function startIntro() {
    if (introStarted || $('#gnezdoIntro')) return;
    introStarted = true;
    document.body.classList.add('gnezdo-intro-active');
    document.body.insertAdjacentHTML('afterbegin', introMarkup());
    const intro = $('#gnezdoIntro');
    const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
    requestAnimationFrame(() => intro?.classList.add('intro-visible'));
    setTimeout(() => intro?.classList.add('intro-logo-ready'), reduced ? 30 : 260);
    setTimeout(() => intro?.classList.add('intro-bird-flight'), reduced ? 70 : 1080);
    setTimeout(() => { intro?.classList.add('intro-split'); document.body.classList.add('gnezdo-intro-reveal'); }, reduced ? 120 : 1750);
    setTimeout(() => { intro?.remove(); document.body.classList.remove('gnezdo-intro-active', 'gnezdo-intro-reveal'); }, reduced ? 260 : 2580);
  }

  function decorateBrand() {
    $$('.mark').forEach(mark => mark.setAttribute('aria-label', 'Логотип Гнездо'));
    const hero = $('.landing .hero > div:first-child');
    if (hero && !$('.hero-brand-signature', hero)) hero.insertAdjacentHTML('afterbegin', `<div class="hero-brand-signature"><img src="${LOGO}" alt="Гнездо"><span><b>Гнездо</b><small>жильё начинается с людей</small></span></div>`);
    const card = $('.landing .aptHero');
    if (card && !$('.hero-logo-stamp', card)) card.insertAdjacentHTML('afterbegin', `<img class="hero-logo-stamp" src="${LOGO}" alt="">`);
  }

  const ownerReplies = {
    greeting:['Здравствуйте! Квартира актуальна. Давайте сразу сверим дату въезда, состав жильцов и ваши вопросы.','Добрый день! Рада знакомству. Спрашивайте — расскажу всё без общих фраз.','Здравствуйте! Да, объявление актуально. Когда планируете заселяться?'],
    price:['Цена в карточке актуальна и фиксируется в договоре. Коммунальные услуги оплачиваются отдельно по квитанциям.','Стоимость аренды не менялась. Если заселяетесь командой, сумму между собой можете распределить как удобно.','Арендная плата актуальна, скрытых комиссий нет.'],
    deposit:['Залог равен одному месяцу, но его можно разбить на два платежа.','Депозит возвращается при выезде после проверки квартиры и закрытия коммунальных счетов.','По залогу можно договориться о двух частях, чтобы вход в аренду был легче.'],
    utilities:['Коммунальные услуги оплачиваются по фактическим квитанциям, счётчики стоят на воду и электричество.','Коммуналка не включена. Перед оплатой я отправляю жильцам квитанции.','Летом сумма обычно ниже, зимой выше из-за отопления.'],
    pets:['С питомцем можно, если вы отвечаете за чистоту и возможный ущерб. Кто у вас?','К кошкам и небольшим собакам отношусь нормально. Лучше познакомиться с питомцем заранее.','Питомцы обсуждаются индивидуально, но запрета как такового нет.'],
    smoking:['В квартире и на балконе не курят, включая электронные сигареты.','Квартира полностью некурящая — это правило будет в договорённостях.','Курение внутри запрещено, на улице рядом есть удобное место.'],
    guests:['Гости допустимы, если это не мешает другим жильцам и соседям. Ночёвки лучше согласовывать.','Обычные гости — без проблем. Длительное проживание другого человека нужно обсудить.','Главное правило — предупреждать соседей по квартире и соблюдать тишину после 23:00.'],
    party:['Шумные вечеринки не подойдут: дом спокойный.','Небольшие встречи допустимы, но без громкой музыки и жалоб соседей.','Формат квартиры скорее спокойный, для больших тусовок она не рассчитана.'],
    viewing:['Показ можно организовать сегодня вечером или завтра после 12:00. Какой интервал удобнее?','Предложите два времени для просмотра — подтвержу одно.','Можем сначала сделать короткий видеопоказ, а потом личную встречу.'],
    documents:['Заключаем договор найма, акт приёма-передачи и опись имущества.','Все документы оформляются официально, перед подписанием спокойно всё прочитаете.','В договоре фиксируются цена, депозит, правила и показания счётчиков.'],
    registration:['Временная регистрация возможна при долгосрочном договоре, обсуждается отдельно.','Регистрацию можно рассмотреть после знакомства и подписания договора.','По временной регистрации готова обсудить условия при просмотре.'],
    furniture:['Квартира меблирована: кровати, шкафы, столы и оборудованная кухня уже есть.','Если хотите привезти свою мебель, лишний предмет можно убрать по договорённости.','Для въезда всё необходимое уже есть.'],
    appliances:['Есть холодильник, стиральная машина, плита, духовка, микроволновка и кондиционер.','Техника рабочая и перечисляется в акте. Обычный ремонт организует собственник.','Базовая бытовая техника уже установлена.'],
    internet:['Подключён стабильный домашний интернет, хватает для удалённой работы и видеозвонков.','Wi‑Fi уже работает, роутер остаётся в квартире.','Тариф можно повысить, если команде нужна большая скорость.'],
    transport:['До остановки около пяти минут пешком, в центр идут прямые маршруты.','Транспорт рядом, основные магазины — в пределах десяти минут.','Район хорошо связан с центром, но в часы пик лучше закладывать запас времени.'],
    parking:['Во дворе есть открытая парковка, закреплённого места нет.','Рядом есть и бесплатные места, и платная стоянка.','Велосипеды можно хранить в закрытом тамбуре.'],
    repair:['Если техника или сантехника ломается не по вине жильцов, ремонт оплачивает собственник.','Пишите о неисправности в общий чат — мастер обычно приходит в течение одного-двух дней.','Серьёзный ремонт полностью беру на себя.'],
    safety:['В подъезде домофон и камеры, двор освещён.','Дом спокойный, камеры стоят у входа и в лифте.','Ключи передаются по акту, есть закрывающийся тамбур.'],
    move:['Квартира готова к заселению. Напишите желаемую дату, и я проверю её.','Заехать можно после просмотра и подписания договора.','Дата въезда гибкая, желательно предупредить хотя бы за два дня.'],
    payment:['Первый платёж вносится после подписания договора и передачи ключей.','Оплата ежемесячная переводом, дата фиксируется в договоре.','Никаких авансов до просмотра и договора не требуется.'],
    owner:['Я собственник и лично подписываю договор, документы покажу при встрече.','Сдаю напрямую без посредников и комиссии.','Да, объявление от собственника.'],
    location:['Точный адрес указан в карточке, перед просмотром пришлю ориентир.','Рядом супермаркет, аптека и остановка.','Дом находится в жилом районе с нормальной инфраструктурой.']
  };

  const personReplies = {
    greeting:['Привет! Рад нашему мэтчу 🙂 Давай сразу сверим бюджет, район и бытовой ритм?','Привет! Я за честный разговор до совместного поиска — спрашивай что угодно.','Привет! Похоже, у нас хороший процент совместимости. С чего начнём?'],
    about:['Я самостоятельный и спокойный человек. Ценю личное пространство, чистую кухню и нормальный диалог.','В будни занят работой, вечером чаще отдыхаю дома. Не требую постоянного общения.','Мне важно заранее договориться о быте и не копить раздражение.'],
    work:['Работаю по будням, иногда из дома. Во время созвонов нужна относительная тишина.','Пару дней в неделю работаю удалённо.','Днём чаще занят, дома в основном утром и вечером.'],
    schedule:['Обычно ложусь около полуночи и встаю в восемь.','Я скорее сова, но ночью веду себя тихо и использую наушники.','График стабильный, без ночных тусовок.'],
    cleaning:['Я за простой график: общие зоны по очереди раз в неделю.','Не фанат стерильности, но посуду и мусор не оставляю.','Можно распределить зоны и менять ответственность каждую неделю.'],
    cooking:['Готовлю несколько раз в неделю и всегда убираю кухню после себя.','Продукты предпочитаю держать отдельно, базовые вещи можно покупать вместе.','Иногда можно делать общий ужин, но без обязательств.'],
    pets:['К животным отношусь хорошо, если хозяин следит за чистотой.','С кошкой или небольшой собакой жить готов.','Лучше заранее обсудить доступ питомца в комнаты.'],
    smoking:['Я не курю и хочу, чтобы внутри квартиры никто не курил.','К курению на улице отношусь спокойно, запаха в квартире не хочу.','Балкон тоже лучше оставить некурящим.'],
    guests:['Гостей зову редко и предупреждаю заранее.','Нормально отношусь к гостям, пока квартира не превращается в проходной двор.','Ночёвки лучше согласовывать друг с другом.'],
    party:['Я за спокойные посиделки, а не громкие вечеринки дома.','Большие компании дома не планирую.','Пару друзей позвать можно, но шум после 23:00 — нет.'],
    budget:['Мой бюджет в анкете актуален, важно заранее посчитать коммуналку и интернет.','Готов держаться указанного диапазона.','Хочу видеть полную сумму до принятия решения.'],
    district:['Приоритет — район из анкеты, но соседние тоже рассматриваю при хорошем транспорте.','Важнее время до работы, чем конкретная улица.','Можно расширить радиус, если дорога занимает не больше сорока минут.'],
    boundaries:['Мне важно стучаться, не брать чужие вещи и говорить о проблемах прямо.','Комнаты приватные, общие зоны общие — простое и понятное правило.','Личное пространство важно, но бытовые вопросы лучше не откладывать.'],
    noise:['Во время работы ценю тишину, ночью использую наушники.','Обычные бытовые звуки не раздражают, громкая музыка ночью — да.','Можно установить тихие часы с 23:00 до 8:00.'],
    move:['По дате гибкий, после хорошего просмотра могу решить за день-два.','Готов заселиться быстро, но сначала хочу спокойно прочитать договор.','Лучше планировать въезд хотя бы за несколько дней.'],
    roommate:['Ищу надёжного и уважительного соседа, а не обязательного лучшего друга.','Хороший сосед выполняет договорённости и умеет обсуждать быт без конфликта.','Хочу спокойный дом без контроля и пассивной агрессии.'],
    compatibility:['У нас совпадают ключевые привычки. Ещё стоит сверить график, гостей и уборку.','Процент хороший, но живой разговор важнее.','Похожий бюджет и формат жизни — уже хорошая база.'],
    ready:['Да, готов искать вместе. Давай создадим гнездо и посмотрим выдачу.','Готов! Можно выбрать три лучших квартиры и идти на просмотры.','Подтверждаю совместный поиск.']
  };

  const commonReplies = {
    thanks:['Пожалуйста! Лучше всё обсудить заранее.','Не за что 🙂 Спрашивайте дальше.','Всегда пожалуйста.'],
    goodbye:['До связи! Я сохраню наши договорённости.','Хорошего дня, вернёмся к разговору в любое время.','Остаёмся на связи.'],
    yes:['Отлично, считаем это предварительно согласованным.','Супер, двигаемся дальше.','Договорились.'],
    no:['Понял, тогда подберём другой вариант.','Спасибо, что сказали прямо.','Принято, не будем включать это в договорённости.'],
    conflict:['Давайте разложим ситуацию на факты и сформулируем одно понятное правило.','Такое лучше обсуждать без обвинений: что произошло и что важно каждому?','Похоже на потенциальное несогласие, лучше зафиксировать решение заранее.'],
    fallback:['Понял общий смысл, но хочу ответить точнее. Речь про квартиру, договор или бытовые привычки?','Добавьте одну деталь — что для вас здесь самое важное?','Сформулируйте вопрос чуть конкретнее, и я дам полезный ответ без общих фраз.']
  };

  const intents = [
    ['greeting',/^(привет|здравствуй|здравствуйте|добрый день|добрый вечер|хай|hello|ку)(\s|$)/i],['thanks',/спасибо|благодар|мерси|спс/i],['goodbye',/до свидания|до связи|пока|увидимся/i],
    ['price',/цен[ауы]|стоим|сколько.*(месяц|аренд)|арендн.*плат/i],['deposit',/залог|депозит|страхов.*взнос/i],['utilities',/коммун|квартплат|счетчик|электр|вода|отоплен/i],['payment',/как.*плат|оплат|перевод|налич|день платеж/i],
    ['pets',/кот|кош|собак|питом|животн|аллерги/i],['smoking',/кури|сигар|вейп|табак|кальян/i],['guests',/гост|друз|ночев|ночёв|партнер.*приход|девушк.*приход|парень.*приход/i],['party',/вечерин|тусов|музык.*гром|шумн.*компан/i],
    ['cleaning',/уборк|чистот|посуд|мусор|дежур|мыть/i],['cooking',/готов|кухн|продукт|еда|холодильник.*полк/i],['internet',/интернет|вай.?фай|wi.?fi|скорост|роутер/i],['furniture',/мебел|кровать|шкаф|стол|диван/i],['appliances',/техник|стирал|холодильник|микроволн|кондиционер|плита|духовк/i],
    ['transport',/транспорт|останов|автобус|трамва|добира/i],['parking',/парков|машин|автомоб|велосипед/i],['repair',/ремонт|сломал|полом|мастер|протеч|сантех/i],['safety',/безопас|камер|домофон|охрана|район.*ноч/i],
    ['documents',/договор|документ|паспорт|акт|официал/i],['registration',/регистрац|пропис/i],['owner',/собственник|владелец|риелтор|агент|комисси/i],['viewing',/просмотр|посмотреть|показ|встрет|видео.*тур/i],['move',/засел|заех|въех|дата|когда.*свобод|с какого/i],['location',/адрес|где.*наход|район|магазин|аптек|центр/i],
    ['work',/работ|офис|удален|удалён|созвон/i],['schedule',/график|ложишь|спишь|встаешь|встаёшь|сова|жаворон/i],['noise',/тишин|шум|громк|наушник/i],['budget',/бюджет|сколько.*готов|по деньгам|дорого/i],['district',/какой район|район.*ищ|локац|далеко.*работ/i],['boundaries',/границ|личн.*простран|брать.*вещ|комнат.*заход/i],['roommate',/какого сосед|что ищешь|ожидани.*сосед|вместе жить/i],['compatibility',/совместим|процент|почему.*подход|мэтч|match/i],['ready',/я готов|готов.*искать|созда.*гнезд|объедин|кластер/i],['about',/расскажи.*себе|чем занима|какой ты|какая ты|о себе/i],['conflict',/конфликт|поруг|бесит|не устраива|проблем/i],['yes',/^(да|ага|ок|окей|хорошо|согласен|согласна|договорились)$/i],['no',/^(нет|неа|не хочу|не подходит|против)$/i]
  ];

  function getActiveChat() {
    if (!Array.isArray(state?.chats) || !state.chats.length) return null;
    let chat = state.chats.find(item => item.id === activeChatId);
    if (!chat) { chat = state.chats[0]; activeChatId = chat.id; }
    return chat;
  }

  function chatMemory(chat) {
    if (!memoryStore[chat.id]) memoryStore[chat.id] = { turns:0,lastIntent:null,userName:null,moveDate:null,budget:null,used:[] };
    return memoryStore[chat.id];
  }

  function extractFacts(message, memory) {
    const name = message.match(/(?:меня зовут|я)\s+([А-ЯЁA-Z][а-яёa-z]{1,20})/); if (name) memory.userName = name[1];
    const budget = message.match(/(?:бюджет|до|готов(?:а)? платить)[^0-9]{0,12}(\d{2,3})(?:\s?000|к\b)/i); if (budget) memory.budget = Number(budget[1]) * 1000;
    const date = message.match(/(?:с|после|примерно)?\s*(\d{1,2})[.\-/](\d{1,2})/); if (date) memory.moveDate = `${date[1].padStart(2,'0')}.${date[2].padStart(2,'0')}`;
  }

  function detect(message) { const text = normalize(message); return intents.filter(([,rx]) => rx.test(text)).map(([id]) => id).slice(0,2); }
  function fresh(pool, memory, salt) { const available = pool.filter(x => !memory.used.slice(-8).includes(x)); const answer = choice(available.length ? available : pool, salt + memory.turns * 17); memory.used.push(answer); memory.used = memory.used.slice(-14); return answer; }

  function composeReply(chat, message) {
    const memory = chatMemory(chat); memory.turns++; extractFacts(message, memory);
    const found = detect(message); const rules = chat.type === 'listing' ? ownerReplies : personReplies; const parts = [];
    for (const intent of found) { const pool = rules[intent] || commonReplies[intent]; if (pool) parts.push(fresh(pool,memory,message.length+intent.length)); }
    if (!parts.length) parts.push(fresh(commonReplies.fallback,memory,message.length+43));
    memory.lastIntent = found[0] || memory.lastIntent; saveMemory();
    let answer = parts.join(' ');
    if (memory.userName && memory.turns % 3 === 0) answer = `${memory.userName}, ${answer.charAt(0).toLowerCase()}${answer.slice(1)}`;
    if (memory.moveDate && /дат|засел|въезд/i.test(answer)) answer += ` Я отметил ориентир ${memory.moveDate}.`;
    if (memory.budget && /бюджет|цен|сумм/i.test(answer)) answer += ` Ваш ориентир ${new Intl.NumberFormat('ru-RU').format(memory.budget)} ₽ тоже сохранил.`;
    return answer;
  }

  function renderMessages(chat) { return chat.messages.map(m => `<div class="msg ${m.from === 'Вы' ? 'me' : ''}"><b>${m.from}</b><div>${String(m.text).replace(/</g,'&lt;').replace(/>/g,'&gt;')}</div><small>сейчас</small></div>`).join(''); }

  function renderChatsStable() {
    const chat = getActiveChat();
    shell(`<div class="view"><div class="head"><div><span class="eyebrow">Единое пространство</span><h1>Сообщения</h1><p>Диалоги остаются на своих местах — переключайтесь без скачков списка.</p></div></div><div class="chatLayout"><aside class="chatList">${state.chats.map((item,index)=>`<div class="chatItem ${item.id===activeChatId?'active':''}" onclick="selectChat(${index})"><img src="${item.avatar}"><div><b>${item.title}</b><p>${item.messages.at(-1)?.text||'Новый диалог'}</p></div></div>`).join('')||'<div class="chat-empty">Пока нет диалогов.</div>'}</aside>${chat?`<section class="chatWindow" data-chat-id="${chat.id}"><header class="chatHeader"><div><b>${chat.title}</b><small>${chat.type==='listing'?'общий чат квартиры':'онлайн недавно · умный собеседник'}</small></div><span class="chat-ai-badge">живой диалог</span></header><div class="messages">${renderMessages(chat)}</div>${chat.type==='person'&&!chat.ready?'<div class="ready"><span>🤝 Готовы искать жильё вместе?</span><button onclick="readyLobby()">Я готов</button></div>':''}<div class="quick-prompts">${(chat.type==='listing'?['Можно с питомцем?','Что входит в оплату?','Когда можно посмотреть?','Как оформляется договор?']:['Расскажи о своём графике','Как делим уборку?','Как относишься к гостям?','Готов искать вместе?']).map(text=>`<button type="button" onclick="sendQuickPrompt('${text.replace(/'/g,"\\'")}')">${text}</button>`).join('')}</div><div class="composer"><input id="message" autocomplete="off" placeholder="Напишите сообщение" onkeydown="if(event.key==='Enter')sendMsg()"><button onclick="sendMsg()">➤</button></div></section>`:'<section class="chatWindow chat-placeholder">Выберите диалог</section>'}</div></div>`);
    requestAnimationFrame(()=>{const messages=$('.messages');if(messages)messages.scrollTop=messages.scrollHeight;});
  }

  function selectChatStable(index) { const selected = state.chats[index]; if (!selected) return; activeChatId = selected.id; renderChatsStable(); }

  function sendSmart(prefilled) {
    const value = String(prefilled ?? $('#message')?.value ?? '').trim(); if (!value) return;
    const chat = getActiveChat(); if (!chat) return;
    chat.messages.push({from:'Вы',text:value}); save(); renderChatsStable();
    const messages = $('.messages'); if (messages) { messages.insertAdjacentHTML('beforeend',`<div class="msg bot-typing"><b>${chat.type==='person'?chat.title:'Владелец'}</b><span><i></i><i></i><i></i></span></div>`); messages.scrollTop=messages.scrollHeight; }
    const reply = composeReply(chat,value); const delay = Math.min(1900,650+value.length*18+Math.floor(Math.random()*420));
    setTimeout(()=>{chat.messages.push({from:chat.type==='person'?chat.title:'Владелец',text:reply});save();if(getActiveChat()?.id===chat.id&&state.tab==='chats')renderChatsStable();else toast(`Новое сообщение: ${chat.title}`);},delay);
  }

  function readyStable() { const chat=getActiveChat(); if(!chat||chat.type!=='person')return; chat.ready=true; if(!state.lobby.includes(chat.personId))state.lobby.push(chat.personId); chat.messages.push({from:'Гнездо',text:`${chat.title} тоже подтвердил(а) совместный поиск. Ваше гнездо собрано!`}); save(); toast('Гнездо собрано — подбор квартир пересчитан'); renderChatsStable(); }

  function patch() {
    decorateBrand();
    if (typeof state === 'undefined' || typeof shell !== 'function') return;
    if (!activeChatId && state.chats?.length) activeChatId = state.chats[0].id;
    globalThis.chatsView = renderChatsStable; globalThis.selectChat = selectChatStable; globalThis.sendMsg = () => sendSmart(); globalThis.sendQuickPrompt = text => sendSmart(text); globalThis.readyLobby = readyStable;
  }

  startIntro(); patch(); new MutationObserver(patch).observe(document.documentElement,{childList:true,subtree:true});
})();