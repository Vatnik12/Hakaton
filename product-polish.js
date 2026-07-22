(() => {
  'use strict';

  const LOGO = '/assets/gnezdo-logo.png';
  let scheduled = false;
  let introPlayed = false;

  const replacements = [
    [/СВОИ/g, 'Гнездо'],
    [/Открыть демо/g, 'Начать поиск'],
    [/Посмотреть мэтчинг/g, 'Посмотреть соседей'],
    [/Запустить рабочий MVP/g, 'Начать поиск'],
    [/рабочий MVP/gi, 'сервис'],
    [/MVP/gi, 'сервис'],
    [/red flags/gi, 'ограничения'],
    [/ярлыки/gi, 'предпочтения'],
    [/Ваше лобби/gi, 'Ваше гнездо'],
    [/вашего лобби/gi, 'вашего гнезда'],
    [/ваше лобби/gi, 'ваше гнездо'],
    [/лобби из/gi, 'командой из'],
    [/лобби/gi, 'гнездо'],
    [/мэтчинг/gi, 'совместимость'],
    [/мэтча/gi, 'совместимости'],
    [/мэтч/gi, 'совпадение'],
    [/Демонстрационные интеграции: реальные документы не отправляются\./g, 'Подтвердите личность удобным способом. Данные защищены и используются только для проверки профиля.'],
    [/Диалоги остаются на своих местах — переключайтесь без скачков списка\./g, 'Все договорённости и важные детали собраны в одном месте.'],
    [/онлайн недавно · умный собеседник/g, 'онлайн недавно'],
    [/живой диалог/g, 'в сети'],
    [/Умная выдача/g, 'Подобрано для вас'],
    [/Свайпы, процент совпадения и чат до принятия решения\./g, 'Сравнивайте образ жизни, привычки и ожидания до совместного решения.']
  ];

  function birdSvg() {
    return `<svg viewBox="0 0 160 100" role="img" aria-label="Летящая птица">
      <path class="wing top" d="M70 48C42 35 26 17 15 7c29 4 54 13 73 31z"/>
      <path class="wing bottom" d="M76 53c-22 13-39 29-49 42 28-7 50-18 67-34z"/>
      <ellipse class="bird-body" cx="93" cy="55" rx="37" ry="17" transform="rotate(-8 93 55)"/>
      <circle class="bird-head" cx="124" cy="43" r="14"/>
      <path class="bird-beak" d="M137 40l21 5-20 7z"/>
      <circle class="bird-eye" cx="128" cy="39" r="2.4"/>
      <path class="bird-tail" d="M61 54 34 44l19 19-17 13 31-8z"/>
    </svg>`;
  }

  function playIntro() {
    if (introPlayed || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    introPlayed = true;

    document.querySelector('#gnezdoIntro')?.remove();
    document.body.classList.remove('gnezdo-intro-active', 'gnezdo-intro-reveal');

    const intro = document.createElement('div');
    intro.className = 'polished-intro';
    intro.setAttribute('aria-label', 'Гнездо');
    intro.innerHTML = `
      <div class="intro-half left"></div>
      <div class="intro-half right"></div>
      <div class="intro-content">
        <img src="${LOGO}" alt="Логотип Гнездо">
        <div class="intro-name">Гнездо</div>
        <div class="intro-tagline">жильё начинается с людей</div>
      </div>
      <div class="cut-line"></div>
      <div class="intro-bird-real" aria-hidden="true">${birdSvg()}</div>`;
    document.body.prepend(intro);

    setTimeout(() => intro.classList.add('is-flying'), 920);
    setTimeout(() => intro.classList.add('is-cut'), 1510);
    setTimeout(() => {
      document.body.classList.add('product-ready');
      intro.classList.add('is-finished');
    }, 2200);
    setTimeout(() => intro.remove(), 2650);
  }

  function replaceText(root = document.body) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        const parent = node.parentElement;
        if (!parent || ['SCRIPT', 'STYLE', 'TEXTAREA'].includes(parent.tagName)) return NodeFilter.FILTER_REJECT;
        return node.nodeValue.trim() ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
      }
    });
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach(node => {
      let value = node.nodeValue;
      replacements.forEach(([pattern, replacement]) => { value = value.replace(pattern, replacement); });
      if (value !== node.nodeValue) node.nodeValue = value;
    });
  }

  function applyBrand() {
    document.querySelectorAll('.logo').forEach(logo => {
      if (logo.dataset.gnezdoBrand === '1') return;
      logo.dataset.gnezdoBrand = '1';
      logo.innerHTML = `<img class="brand-logo" src="${LOGO}" alt=""><span class="brand-word">Гнездо</span>`;
      logo.setAttribute('aria-label', 'Гнездо');
    });

    document.querySelectorAll('.hero-brand-signature img').forEach(image => {
      image.src = LOGO;
      image.removeAttribute('style');
    });

    document.querySelector('.backend-status')?.remove();
  }

  function ensureAtmosphere() {
    if (document.querySelector('.forest-atmosphere')) return;
    const atmosphere = document.createElement('div');
    atmosphere.className = 'forest-atmosphere';
    atmosphere.setAttribute('aria-hidden', 'true');
    atmosphere.innerHTML = `<div class="forest-grid"></div>
      <div class="forest-branch branch-a"><i></i><i></i><i></i><i></i></div>
      <div class="forest-branch branch-b"><i></i><i></i><i></i><i></i></div>`;
    document.body.append(atmosphere);
  }

  function prepareScrollReveals() {
    const elements = document.querySelectorAll('.feature, .sectionTitle, .card, .personCard, .insights');
    elements.forEach(element => {
      if (element.dataset.revealReady === '1') return;
      element.dataset.revealReady = '1';
      element.classList.add('reveal-on-scroll');
      revealObserver.observe(element);
    });
  }

  const revealObserver = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add('is-visible');
      revealObserver.unobserve(entry.target);
    });
  }, { threshold: 0.08, rootMargin: '0px 0px -30px' });

  function polish() {
    scheduled = false;
    applyBrand();
    replaceText();
    ensureAtmosphere();
    prepareScrollReveals();
  }

  function schedulePolish() {
    if (scheduled) return;
    scheduled = true;
    requestAnimationFrame(polish);
  }

  let ticking = false;
  addEventListener('scroll', () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      document.documentElement.style.setProperty('--scroll-shift', `${scrollY}px`);
      ticking = false;
    });
  }, { passive: true });

  playIntro();
  schedulePolish();
  new MutationObserver(schedulePolish).observe(document.documentElement, { childList: true, subtree: true });
})();
