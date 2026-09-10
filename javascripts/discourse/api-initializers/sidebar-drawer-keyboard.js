import { registerDestructor } from "@ember/destroyable";
import { schedule } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  const header = api.container.lookup("service:header");
  const site = api.container.lookup("service:site");
  const appEvents = api.container.lookup("service:app-events");

  const closeDrawer = (event) => {
    if (
      event.key !== "Escape" ||
      event.defaultPrevented ||
      !header.hamburgerVisible ||
      !(site.mobileView || site.narrowDesktopView) ||
      !document.querySelector(".sidebar-hamburger-dropdown") ||
      document.querySelector(".d-modal, .fk-d-menu.-expanded")
    ) {
      return;
    }

    event.preventDefault();
    // Use the header action so its scroll lock and menu state stay in sync.
    appEvents.trigger("header:keyboard-trigger", { type: "hamburger" });
    schedule("afterRender", () => {
      document.getElementById("toggle-hamburger-menu")?.focus();
    });
  };

  document.addEventListener("keydown", closeDrawer);
  registerDestructor(header, () => {
    document.removeEventListener("keydown", closeDrawer);
  });
});
