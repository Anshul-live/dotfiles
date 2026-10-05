// ==UserScript==
// @name         youtube-focus
// @description  YouTube for learning: search + watch only. No home feed, Shorts or recommendations.
// @match        *://*.youtube.com/*
// @run-at       document-start
// ==/UserScript==
// qutebrowser greasemonkey script, linked into ~/.qutebrowser/greasemonkey/ by install.sh.
// config.py redirects full page loads of feeds/Shorts; this covers YouTube's in-page (SPA)
// navigation, which never reloads, and hides the recommendation surfaces on allowed pages.
// Hard block on purpose: changing it means editing dotfiles, not clicking a toggle.
(() => {
  "use strict";

  // same list as YT_BLOCKED in config.py
  const BLOCKED =
    /^\/(shorts(\/|$)|(@[^/]+|c\/[^/]+|channel\/[^/]+|user\/[^/]+)\/shorts|gaming|hashtag\/|feed\/(?!(subscriptions|history|playlists|library|you|channels|downloads)\b))/;

  const CSS = `
    /* home feed: an empty page with the search box */
    ytd-browse[page-subtype="home"] #primary,
    ytd-browse[page-subtype="home"] #header,
    ytd-browse[page-subtype="home"] #chips-wrapper,
    ytm-browse ytm-rich-grid-renderer,
    /* watch page: related videos, end screens, autoplay countdown, fullscreen grid */
    ytd-watch-flexy #related,
    ytd-watch-next-secondary-results-renderer,
    .ytp-endscreen-content, .ytp-ce-element, .ytp-videowall-still,
    .ytp-autonav-endscreen-countdown-overlay, .ytp-upnext, .ytp-suggestion-set,
    .ytp-fullscreen-grid, .ytp-fullscreen-grid-stills-container,
    .ytp-pause-overlay, .ytp-autonav-toggle-button-container,
    ytm-item-section-renderer[section-identifier="related-items"],
    /* Shorts anywhere: shelves, results, sidebar entries, channel tab */
    ytd-reel-shelf-renderer, ytd-rich-shelf-renderer[is-shorts],
    ytm-reel-shelf-renderer, ytm-shorts-lockup-view-model, ytm-shorts-lockup-view-model-v2,
    grid-shelf-view-model:has(ytm-shorts-lockup-view-model),
    ytd-video-renderer:has(a[href^="/shorts/"]),
    ytd-guide-entry-renderer:has(a[title="Shorts"]),
    ytd-mini-guide-entry-renderer[aria-label="Shorts"],
    yt-tab-shape[tab-title="Shorts"],
    /* sidebar Explore section (Trending, Music, Gaming, ...) */
    ytd-guide-section-renderer:has(a[href^="/feed/trending"]),
    ytd-guide-section-renderer:has(a[href^="/gaming"]),
    /* "People also watched" / "For you" shelves inside search results */
    ytd-search ytd-shelf-renderer, ytd-search ytd-horizontal-card-list-renderer
    { display: none !important; }
  `;

  const style = document.createElement("style");
  style.textContent = CSS;
  (document.head || document.documentElement).appendChild(style);

  const check = () => {
    if (BLOCKED.test(location.pathname)) {
      location.replace("/");
      return;
    }
    if (location.pathname === "/") {
      // home is blank: put the cursor in search instead
      const box = document.querySelector('input[name="search_query"]');
      if (box) box.focus();
    }
    // autoplay would pick the next (recommended) video: keep it off
    const autonav = document.querySelector('.ytp-autonav-toggle-button[aria-checked="true"]');
    if (autonav) autonav.click();
  };

  // yt-navigate-finish fires after every SPA page change; popstate covers back/forward
  document.addEventListener("yt-navigate-finish", check);
  window.addEventListener("popstate", check);
  document.addEventListener("DOMContentLoaded", check);
  check();
})();
