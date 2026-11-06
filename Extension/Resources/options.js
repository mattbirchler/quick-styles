const list = document.getElementById("list");
const empty = document.getElementById("empty");
const filter = document.getElementById("filter");
const template = document.getElementById("entry-template");
const timers = new Map();

function sortKeys(keys) {
  // "All sites" first, then sites alphabetically.
  return keys
    .filter((k) => k === QuickStyles.GLOBAL_KEY || QuickStyles.isSiteKey(k))
    .sort((a, b) => {
      if (a === QuickStyles.GLOBAL_KEY) return -1;
      if (b === QuickStyles.GLOBAL_KEY) return 1;
      return a.localeCompare(b);
    });
}

function labelFor(key) {
  return key === QuickStyles.GLOBAL_KEY ? "All sites" : QuickStyles.hostFromKey(key);
}

async function render() {
  const items = await browser.storage.local.get(null);
  list.replaceChildren();
  for (const key of sortKeys(Object.keys(items))) {
    const entry = items[key];
    const node = template.content.firstElementChild.cloneNode(true);
    const css = node.querySelector(".entry-css");
    const enabled = node.querySelector(".entry-enabled");

    node.dataset.key = key;
    node.querySelector(".entry-name").textContent = labelFor(key);
    css.value = entry.css ?? "";
    enabled.checked = entry.enabled !== false;
    node.classList.toggle("off", !enabled.checked);

    const save = () => {
      clearTimeout(timers.get(key));
      timers.delete(key);
      node.classList.toggle("off", !enabled.checked);
      return browser.storage.local.set({ [key]: { css: css.value, enabled: enabled.checked } });
    };
    css.addEventListener("input", () => {
      clearTimeout(timers.get(key));
      timers.set(key, setTimeout(save, 300));
    });
    enabled.addEventListener("change", save);
    node.querySelector(".entry-delete").addEventListener("click", async () => {
      if (!confirm(`Delete the styles for ${labelFor(key)}?`)) return;
      await browser.storage.local.remove(key);
      node.remove();
      updateEmpty();
    });
    list.appendChild(node);
  }
  applyFilter();
}

function applyFilter() {
  const q = filter.value.trim().toLowerCase();
  for (const node of list.children) {
    node.hidden = !!q && !labelFor(node.dataset.key).toLowerCase().includes(q);
  }
  updateEmpty();
}

function updateEmpty() {
  empty.hidden = list.children.length > 0;
}

filter.addEventListener("input", applyFilter);

document.getElementById("export").addEventListener("click", async () => {
  const items = await browser.storage.local.get(null);
  const styles = {};
  for (const key of sortKeys(Object.keys(items))) styles[key] = items[key];
  const blob = new Blob([JSON.stringify({ app: "Quick Styles", version: 1, styles }, null, 2)], { type: "application/json" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `quick-styles-${new Date().toISOString().slice(0, 10)}.json`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(link.href), 1000);
});

const importFile = document.getElementById("import-file");
document.getElementById("import").addEventListener("click", () => importFile.click());
importFile.addEventListener("change", async () => {
  const file = importFile.files?.[0];
  importFile.value = "";
  if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    const styles = data?.styles ?? {};
    const valid = {};
    for (const [key, entry] of Object.entries(styles)) {
      if ((key === QuickStyles.GLOBAL_KEY || QuickStyles.isSiteKey(key)) && typeof entry?.css === "string") {
        valid[key] = { css: entry.css, enabled: entry.enabled !== false };
      }
    }
    const count = Object.keys(valid).length;
    if (count === 0) throw new Error("no styles");
    if (!confirm(`Import ${count} style${count === 1 ? "" : "s"}? Sites you already have styles for will be replaced.`)) return;
    await browser.storage.local.set(valid);
    await render();
  } catch {
    alert("That file doesn't look like a Quick Styles export.");
  }
});

// Stay in sync with edits made from the popup.
browser.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  const editing = document.activeElement?.closest?.(".entry");
  if (!editing) render();
});

render();
