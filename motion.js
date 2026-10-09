// MotionSites-inspired, original lightweight motion choreography for Intactoz.
// Progressive enhancement: content is visible without JS / when reduced motion is enabled.
const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
let observer = null;
let currentHero = null;
let scrollScheduled = false;
let scrollListenerReady = false;
let progressBar = null;

const revealSelectors = [
  '.hero-inner .eyebrow', '.hero h1', '.hero-copy', '.hero-actions',
  '.section-head > *', '.category-tabs', '.filters-bottom', '.product-grid .product',
  '.catalog-bottom > *', '.editorial-head > *', '.editorial-grid > *',
  '.universe > .eyebrow', '.universe-icon', '.universe h2', '.universe-bottom > *',
  '.footer-main > *', '.page-header > *', '.account-left > *',
  '.account-grid > .box', '.stat-row > *', '.admin-tabs',
  '.admin-list', '.tax-grid > *', '.admin-locked > *'
];

function updateScrollEffects() {
  scrollScheduled = false;
  if (reducedMotion.matches || document.hidden) return;

  const maxScroll = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
  const progress = Math.min(1, Math.max(0, window.scrollY / maxScroll));
  if (progressBar) progressBar.style.transform = `scaleX(${progress.toFixed(4)})`;

  if (currentHero) {
    const rect = currentHero.getBoundingClientRect();
    const nearHero = rect.bottom > 0 && rect.top < window.innerHeight;
    // Small background movement for depth, never moves layout or text.
    if (nearHero) {
      const amount = Math.max(-36, Math.min(36, (window.scrollY - currentHero.offsetTop) * 0.09));
      currentHero.style.setProperty('--hero-drift', `${amount.toFixed(1)}px`);
    }
  }
}
function requestScrollEffects() {
  if (scrollScheduled) return;
  scrollScheduled = true;
  window.requestAnimationFrame(updateScrollEffects);
}
function ensureProgressBar() {
  if (progressBar) return;
  progressBar = document.createElement('div');
  progressBar.className = 'motion-scroll-progress';
  progressBar.setAttribute('aria-hidden', 'true');
  document.body.append(progressBar);
}

function mountMotions() {
  observer?.disconnect();
  currentHero = document.querySelector('#main-content .hero');
  if (reducedMotion.matches) {
    document.querySelectorAll('.motion-reveal').forEach(el => {
      el.classList.remove('motion-reveal', 'motion-in');
      el.style.removeProperty('--reveal-delay');
    });
    progressBar?.remove();
    progressBar = null;
    currentHero?.style.removeProperty('--hero-drift');
    return;
  }

  ensureProgressBar();
  if (!scrollListenerReady) {
    window.addEventListener('scroll', requestScrollEffects, {passive:true});
    window.addEventListener('resize', requestScrollEffects, {passive:true});
    scrollListenerReady = true;
  }

  if (!('IntersectionObserver' in window)) {
    requestScrollEffects();
    return;
  }

  const targets = [...new Set(revealSelectors.flatMap(selector =>
    [...document.querySelectorAll(`#main-content ${selector}, #footer ${selector}`)]
  ))];
  observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('motion-in');
        observer?.unobserve(entry.target);
      }
    });
  }, {threshold:0.08, rootMargin:'0px 0px -35px 0px'});

  targets.forEach((element, index) => {
    // Don't flash elements already visible while filtering products / navigating tabs.
    const box = element.getBoundingClientRect();
    if (window.scrollY > 100 && box.top < window.innerHeight * .85 && box.bottom > 0) return;
    // Stagger each row of product cards, not the whole page.
    const cardPosition = element.matches('.product') ?
      [...element.parentElement.children].indexOf(element) % 4 : index % 4;
    element.style.setProperty('--reveal-delay', `${cardPosition * 85}ms`);
    element.classList.add('motion-reveal');
    observer.observe(element);
  });
  requestScrollEffects();
}
reducedMotion.addEventListener?.('change', () => mountMotions());

window.intactozMountMotions = mountMotions;
