import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

const COMMUNITY_ENTRY_ID = "moaclab-community-entry";

function externalUrl(value) {
  if (!value) {
    return null;
  }

  try {
    const url = new URL(value);
    return ["http:", "https:"].includes(url.protocol) ? url.href : null;
  } catch {
    return null;
  }
}

function text(key, fallback) {
  return i18n(themePrefix(key)) || fallback;
}

function communityChannels() {
  return [
    {
      className: "moaclab-community-entry__channel--qq",
      href: externalUrl(settings.community_qq_url),
      label: text("community_qq", "QQ Group"),
    },
    {
      className: "moaclab-community-entry__channel--discord",
      href: externalUrl(settings.community_discord_url),
      label: text("community_discord", "Discord"),
    },
  ].filter(({ href }) => href);
}

function createChannel(channel) {
  const item = document.createElement("a");
  item.className = `moaclab-community-entry__channel ${channel.className}`;
  item.href = channel.href;
  item.target = "_blank";
  item.rel = "noopener noreferrer";

  const label = document.createElement("span");
  label.textContent = channel.label;
  item.append(label);

  const open = document.createElement("span");
  open.className = "moaclab-community-entry__open";
  open.textContent = `${text("community_open", "Open")} ↗`;
  item.append(open);

  return item;
}

function ensureCommunityEntry() {
  const channels = communityChannels();
  const existing = document.getElementById(COMMUNITY_ENTRY_ID);

  if (!channels.length) {
    existing?.remove();
    return;
  }

  if (existing || !document.body) {
    return;
  }

  const entry = document.createElement("section");
  entry.id = COMMUNITY_ENTRY_ID;
  entry.className = "moaclab-community-entry";

  const menu = document.createElement("div");
  menu.className = "moaclab-community-entry__menu";
  menu.id = `${COMMUNITY_ENTRY_ID}-menu`;
  menu.hidden = true;
  menu.setAttribute("role", "dialog");
  menu.setAttribute("aria-labelledby", `${COMMUNITY_ENTRY_ID}-title`);

  const title = document.createElement("p");
  title.id = `${COMMUNITY_ENTRY_ID}-title`;
  title.className = "moaclab-community-entry__title";
  title.textContent = text(
    "community_menu_title",
    "Join the Moaclab community"
  );
  menu.append(title);

  const channelList = document.createElement("div");
  channelList.className = "moaclab-community-entry__channels";
  channels.forEach((channel) => channelList.append(createChannel(channel)));
  menu.append(channelList);

  const trigger = document.createElement("button");
  trigger.className = "moaclab-community-entry__trigger";
  trigger.type = "button";
  trigger.setAttribute("aria-controls", menu.id);
  trigger.setAttribute("aria-expanded", "false");
  trigger.setAttribute(
    "aria-label",
    text("community_menu_label", "Community links")
  );

  const icon = document.createElement("span");
  icon.className = "moaclab-community-entry__trigger-icon";
  icon.setAttribute("aria-hidden", "true");
  trigger.append(icon);

  const label = document.createElement("span");
  label.className = "moaclab-community-entry__trigger-label";
  label.textContent = text("community_join", "Join community");
  trigger.append(label);

  const close = () => {
    menu.hidden = true;
    trigger.setAttribute("aria-expanded", "false");
  };

  trigger.addEventListener("click", () => {
    const isOpen = !menu.hidden;
    menu.hidden = isOpen;
    trigger.setAttribute("aria-expanded", String(!isOpen));
  });

  document.addEventListener("pointerdown", (event) => {
    if (!entry.contains(event.target)) {
      close();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !menu.hidden) {
      close();
      trigger.focus();
    }
  });

  entry.append(menu, trigger);
  document.body.append(entry);
}

export default apiInitializer(() => {
  ensureCommunityEntry();
});
