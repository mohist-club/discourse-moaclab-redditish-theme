import { apiInitializer } from "discourse/lib/api";

const HIDDEN_CLASS = "moaclab-sidebar-tags-hidden";

export default apiInitializer(() => {
  document.body?.classList.toggle(HIDDEN_CLASS, !settings.sidebar_tags_enabled);
});
