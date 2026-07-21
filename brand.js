(() => {
  const replacements = new Map([
    ['СВОИ', 'Гнездо'],
    ['Найти своих →', 'Найти своё гнездо →'],
    ['Запустить рабочий MVP', 'Открыть Гнездо'],
    ['Найти квартиру, где вам будут рады', 'Найдите место, где хочется остаться'],
    ['Квартиры для вашего лобби', 'Квартиры для вашего гнезда'],
    ['Ваше лобби', 'Ваше гнездо'],
    ['Создайте лобби', 'Соберите своё гнездо'],
    ['Лобби создано!', 'Ваше гнездо собрано!'],
    ['Лобби создано — подбор квартир пересчитан', 'Гнездо собрано — подбор квартир пересчитан']
  ]);

  const decorateLanding = () => {
    const landing = document.querySelector('.landing');
    if (!landing || landing.dataset.gnezdoDecorated) return;
    landing.dataset.gnezdoDecorated = '1';
    landing.insertAdjacentHTML('beforeend', `
      <span class="bird one" aria-hidden="true"></span>
      <span class="bird two" aria-hidden="true"></span>
      <span class="bird three" aria-hidden="true"></span>
      <span class="branch heroBranch" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
      <span class="branch leftBranch" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
    `);
    const features = document.querySelector('.features .wrap');
    if (features && !features.querySelector('.twig-divider')) {
      const title = features.querySelector('.sectionTitle');
      title?.insertAdjacentHTML('afterend', '<div class="twig-divider" aria-hidden="true"></div>');
    }
  };

  const replaceText = root => {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach(node => {
      let text = node.nodeValue;
      replacements.forEach((to, from) => { text = text.split(from).join(to); });
      node.nodeValue = text;
    });
  };

  const addFlightLayer = () => {
    if (document.querySelector('.gnezdo-flight')) return;
    document.body.insertAdjacentHTML('beforeend', `
      <div class="gnezdo-flight" aria-hidden="true">
        <span class="scroll-bird" style="left:8%;top:22%"></span>
        <span class="scroll-bird" style="left:78%;top:48%;transform:scale(.72)"></span>
        <span class="scroll-bird" style="left:34%;top:76%;transform:scale(.55)"></span>
      </div>
    `);
  };

  const moveBirds = () => {
    const y = window.scrollY;
    document.querySelectorAll('.scroll-bird').forEach((bird, index) => {
      const direction = index % 2 ? -1 : 1;
      const base = [0, 70, -40][index] || 0;
      bird.style.translate = `${base + y * .08 * direction}px ${Math.sin(y / 180 + index) * 14}px`;
      bird.style.opacity = y < 80 ? '.15' : '.72';
    });
  };

  const apply = () => {
    replaceText(document.body);
    decorateLanding();
    addFlightLayer();
  };

  const observer = new MutationObserver(() => apply());
  observer.observe(document.documentElement, { childList: true, subtree: true });
  window.addEventListener('scroll', moveBirds, { passive: true });
  apply();
  moveBirds();
})();