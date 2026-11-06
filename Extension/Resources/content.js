(() => {
  const STYLE_ID = "quick-styles-user-css";
  const globalKey = QuickStyles.GLOBAL_KEY;
  const siteKey = QuickStyles.siteKey(location.hostname);
  const state = {};
  let styleEl = null;

  // Keep our <style> as the last element in the document so it wins
  // over the page's own stylesheets at equal specificity.
  function place() {
    const root = document.documentElement;
    if (!styleEl || !root) return;
    if (styleEl.parentNode !== root || root.lastElementChild !== styleEl) {
      root.appendChild(styleEl);
    }
  }

  function render() {
    const parts = [];
    if (QuickStyles.isActive(state[globalKey])) parts.push(state[globalKey].css);
    if (QuickStyles.isActive(state[siteKey])) parts.push(state[siteKey].css);

    if (parts.length === 0) {
      styleEl?.remove();
      return;
    }
    if (!styleEl) {
      styleEl = document.createElement("style");
      styleEl.id = STYLE_ID;
    }
    const css = parts.join("\n\n");
    if (styleEl.textContent !== css) styleEl.textContent = css;
    place();
  }

  browser.storage.local.get([globalKey, siteKey]).then((items) => {
    Object.assign(state, items);
    render();
  });

  // Live updates while you type in the popup.
  browser.storage.onChanged.addListener((changes, area) => {
    if (area !== "local") return;
    let touched = false;
    for (const key of [globalKey, siteKey]) {
      if (key in changes) {
        state[key] = changes[key].newValue;
        touched = true;
      }
    }
    if (touched) render();
  });

  // The page's <head> and <body> get parsed after document_start, so move
  // our style back to the end once they exist.
  document.addEventListener("DOMContentLoaded", place, { once: true });
  window.addEventListener("load", place, { once: true });

  // Lets the popup ask which site this tab is on.
  browser.runtime.onMessage.addListener((message) => {
    if (message?.type === "quick-styles:get-host" && window === window.top) {
      return Promise.resolve({ hostname: location.hostname, protocol: location.protocol });
    }
  });
})();
