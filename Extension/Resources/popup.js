const els = {
  tabSite: document.getElementById("tab-site"),
  tabGlobal: document.getElementById("tab-global"),
  enabled: document.getElementById("enabled"),
  target: document.getElementById("target"),
  css: document.getElementById("css"),
  notice: document.getElementById("notice"),
  status: document.getElementById("status"),
  manage: document.getElementById("manage")
};

let host = null;          // normalized host of the current tab, or null
let scope = "site";       // "site" or "global"
let saveTimer = null;
let statusTimer = null;

function currentKey() {
  return scope === "global" ? QuickStyles.GLOBAL_KEY : QuickStyles.siteKey(host);
}

async function findHost() {
  const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
  let url = null;
  try { url = tab?.url ? new URL(tab.url) : null; } catch { url = null; }

  // Without the tabs permission Safari may hide the URL, so ask the page.
  if (!url && tab?.id != null) {
    try {
      const reply = await browser.tabs.sendMessage(tab.id, { type: "quick-styles:get-host" });
      if (reply?.hostname) url = { hostname: reply.hostname, protocol: reply.protocol };
    } catch { /* content script not allowed on this page */ }
  }

  if (url && /^https?:$/.test(url.protocol) && url.hostname) {
    return QuickStyles.normalizeHost(url.hostname);
  }
  return null;
}

async function load() {
  els.tabSite.setAttribute("aria-selected", String(scope === "site"));
  els.tabGlobal.setAttribute("aria-selected", String(scope === "global"));

  if (scope === "site" && !host) {
    els.target.textContent = "No website open";
    els.css.value = "";
    els.css.disabled = true;
    els.enabled.disabled = true;
    showNotice("Open a website, then click Quick Styles to add CSS for it. If you're on a website, make sure Quick Styles is allowed to run there (Safari > Settings > Websites).");
    return;
  }

  els.target.textContent = scope === "global" ? "Every website" : host;
  showNotice(null);
  els.css.disabled = false;
  els.enabled.disabled = false;

  const key = currentKey();
  const entry = (await browser.storage.local.get(key))[key];
  els.css.value = entry?.css ?? "";
  els.enabled.checked = entry?.enabled !== false;
  els.css.focus();
}

function showNotice(text) {
  els.notice.hidden = !text;
  els.notice.textContent = text ?? "";
}

function flashStatus(text) {
  els.status.textContent = text;
  clearTimeout(statusTimer);
  statusTimer = setTimeout(() => { els.status.textContent = ""; }, 1500);
}

async function save() {
  clearTimeout(saveTimer);
  saveTimer = null;
  const key = currentKey();
  const css = els.css.value;
  if (!css.trim()) {
    await browser.storage.local.remove(key);
  } else {
    await browser.storage.local.set({ [key]: { css, enabled: els.enabled.checked } });
  }
  flashStatus("Saved");
}

function scheduleSave() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(save, 200);
}

async function switchScope(next) {
  if (next === scope) return;
  if (saveTimer) await save();
  scope = next;
  await load();
}

els.css.addEventListener("input", scheduleSave);
els.enabled.addEventListener("change", save);
els.tabSite.addEventListener("click", () => switchScope("site"));
els.tabGlobal.addEventListener("click", () => switchScope("global"));
els.manage.addEventListener("click", () => {
  browser.runtime.openOptionsPage();
  window.close();
});

// Tab inserts two spaces instead of leaving the editor.
els.css.addEventListener("keydown", (event) => {
  if (event.key !== "Tab" || event.shiftKey || event.metaKey || event.ctrlKey || event.altKey) return;
  event.preventDefault();
  const { selectionStart: start, selectionEnd: end, value } = els.css;
  els.css.value = value.slice(0, start) + "  " + value.slice(end);
  els.css.selectionStart = els.css.selectionEnd = start + 2;
  scheduleSave();
});

// Save anything pending if the popup closes mid-typing.
window.addEventListener("pagehide", () => { if (saveTimer) save(); });

(async () => {
  host = await findHost();
  if (!host) scope = "global";
  await load();
  if (!host) {
    // Still show why "This site" is unavailable.
    els.tabSite.disabled = true;
    els.tabSite.title = "Open a website to add CSS for it";
  }
})();
