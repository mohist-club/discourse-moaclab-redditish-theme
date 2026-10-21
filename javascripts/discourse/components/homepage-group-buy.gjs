import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";

function safeUrl(value, image) {
  if (typeof value !== "string" || !value.trim()) {
    return null;
  }
  try {
    const url = new URL(value, window.location.origin);
    if (
      url.protocol !== "https:" ||
      (!image && url.origin !== window.location.origin)
    ) {
      return null;
    }
    return url.href;
  } catch {
    return null;
  }
}

function configuredItems() {
  let rawItems;
  try {
    rawItems = JSON.parse(settings.homepage_gb_items || "[]");
  } catch {
    rawItems = [];
  }
  if (!Array.isArray(rawItems)) {
    rawItems = [];
  }
  if (!rawItems.length) {
    rawItems = [
      {
        title: settings.homepage_gb_title,
        image_url: settings.homepage_gb_image_url,
        topic_url: settings.homepage_gb_topic_url,
      },
    ];
  }
  return rawItems.flatMap((item) => {
    const title = typeof item?.title === "string" ? item.title.trim() : "";
    const image = safeUrl(item?.image_url, true);
    const topic = safeUrl(item?.topic_url, false);
    return title && image && topic ? [{ title, image, topic }] : [];
  });
}

export default class HomepageGroupBuy extends Component {
  @tracked index = 0;
  items = configuredItems();
  hovering = false;
  focused = false;

  constructor() {
    super(...arguments);
    if (this.items.length > 1) {
      this.timer = window.setInterval(() => {
        if (
          !this.hovering &&
          !this.focused &&
          !window.matchMedia("(prefers-reduced-motion: reduce)").matches
        ) {
          this.index = (this.index + 1) % this.items.length;
        }
      }, 6000);
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    window.clearInterval(this.timer);
  }

  get slides() {
    return this.items.map((item, index) => ({
      ...item,
      active: index === this.index,
      tabIndex: index === this.index ? 0 : -1,
    }));
  }

  get trackStyle() {
    return htmlSafe(`transform: translateX(-${this.index * 100}%);`);
  }

  get multiple() {
    return this.items.length > 1;
  }

  @action
  previous() {
    this.index = (this.index + this.items.length - 1) % this.items.length;
  }

  @action
  next() {
    this.index = (this.index + 1) % this.items.length;
  }

  @action
  pauseHover() {
    this.hovering = true;
  }

  @action
  resumeHover() {
    this.hovering = false;
  }

  @action
  pauseFocus() {
    this.focused = true;
  }

  @action
  resumeFocus(event) {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      this.focused = false;
    }
  }

  <template>
    {{#if this.items.length}}
      <section
        class="moaclab-home-gb"
        aria-label="社区 GB 作品"
        {{on "mouseenter" this.pauseHover}}
        {{on "mouseleave" this.resumeHover}}
        {{on "focusin" this.pauseFocus}}
        {{on "focusout" this.resumeFocus}}
      >
        <div class="moaclab-home-gb__track" style={{this.trackStyle}}>
          {{#each this.slides as |item|}}
            <a
              class="moaclab-home-gb__slide"
              href={{item.topic}}
              tabindex={{item.tabIndex}}
              aria-hidden={{if item.active "false" "true"}}
            >
              <img src={{item.image}} alt="" />
              <span class="moaclab-home-gb__content">
                <span class="moaclab-home-gb__label">社区作品 · GB</span>
                <strong>{{item.title}}</strong>
                <span class="moaclab-home-gb__link">查看作品 →</span>
              </span>
            </a>
          {{/each}}
        </div>
        {{#if this.multiple}}
          <button
            class="moaclab-home-gb__arrow moaclab-home-gb__arrow--previous"
            type="button"
            aria-label="上一个作品"
            title="上一个作品"
            {{on "click" this.previous}}
          >{{icon "chevron-left"}}</button>
          <button
            class="moaclab-home-gb__arrow moaclab-home-gb__arrow--next"
            type="button"
            aria-label="下一个作品"
            title="下一个作品"
            {{on "click" this.next}}
          >{{icon "chevron-right"}}</button>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
