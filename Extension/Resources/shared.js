// Helpers shared by the content script, popup, and options page.
// Storage layout (browser.storage.local):
//   "global"            -> { css, enabled }   applies to every site
//   "site:example.com"  -> { css, enabled }   applies to that host ("www." ignored)
var QuickStyles = {
  GLOBAL_KEY: "global",
  SITE_PREFIX: "site:",

  normalizeHost(hostname) {
    return (hostname || "").toLowerCase().replace(/^www\./, "");
  },

  siteKey(host) {
    return this.SITE_PREFIX + this.normalizeHost(host);
  },

  isSiteKey(key) {
    return key.startsWith(this.SITE_PREFIX);
  },

  hostFromKey(key) {
    return key.slice(this.SITE_PREFIX.length);
  },

  isActive(entry) {
    return !!entry && entry.enabled !== false && !!(entry.css || "").trim();
  }
};
