(() => {
  const globalKey = QuickStyles.GLOBAL_KEY;
  const siteKey = QuickStyles.siteKey(location.hostname);
  const state = {};

  // A constructed stylesheet instead of a <style> element: sites with a
  // strict Content Security Policy (e.g. Mastodon's style-src nonce) block
  // injected <style> tags in Safari, but CSP doesn't apply to adopted
  // sheets. Adopted sheets also cascade after the page's own stylesheets,
  // so ours wins at equal specificity.
  const sheet = new CSSStyleSheet();
  let currentCSS = "";

  function attach() {
    if (!document.adoptedStyleSheets.includes(sheet)) {
      document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet];
    }
  }

  function detach() {
    if (document.adoptedStyleSheets.includes(sheet)) {
      document.adoptedStyleSheets = document.adoptedStyleSheets.filter((s) => s !== sheet);
    }
  }

  function render() {
    const parts = [];
    if (QuickStyles.isActive(state[globalKey])) parts.push(state[globalKey].css);
    if (QuickStyles.isActive(state[siteKey])) parts.push(state[siteKey].css);

    if (parts.length === 0) {
      detach();
      return;
    }
    const css = parts.join("\n\n");
    if (css !== currentCSS) {
      sheet.replaceSync(css);
      currentCSS = css;
    }
    attach();
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

  // Lets the popup ask which site this tab is on.
  browser.runtime.onMessage.addListener((message) => {
    if (message?.type === "quick-styles:get-host" && window === window.top) {
      return Promise.resolve({ hostname: location.hostname, protocol: location.protocol });
    }
  });
})();
