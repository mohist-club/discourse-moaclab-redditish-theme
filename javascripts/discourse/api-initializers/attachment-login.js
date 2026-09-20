import { registerDestructor } from "@ember/destroyable";
import { apiInitializer } from "discourse/lib/api";

function isPrimaryUnmodifiedClick(event) {
  return (
    event.button === 0 &&
    !event.metaKey &&
    !event.ctrlKey &&
    !event.shiftKey &&
    !event.altKey
  );
}

export default apiInitializer((api) => {
  const applicationRoute = api.container.lookup("route:application");

  const requireLoginForAttachment = (event) => {
    if (
      api.getCurrentUser() ||
      event.defaultPrevented ||
      !isPrimaryUnmodifiedClick(event) ||
      !(event.target instanceof Element) ||
      !event.target.closest("a.attachment")
    ) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    applicationRoute.send("showLogin");
  };

  document.addEventListener("click", requireLoginForAttachment, true);
  registerDestructor(applicationRoute, () => {
    document.removeEventListener("click", requireLoginForAttachment, true);
  });
});
