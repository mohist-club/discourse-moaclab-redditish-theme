import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
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
  const rawItems = Array.isArray(settings.homepage_gb_works)
    ? settings.homepage_gb_works
    : [];
  return rawItems.flatMap((item) => {
    const title = typeof item?.title === "string" ? item.title.trim() : "";
    const topic = safeUrl(item?.topic_url, false);
    const path = topic && new URL(topic).pathname;
    const match = path?.match(/\/t\/(?:[^/]+\/)?(\d+)(?:\/\d+)?\/?$/);
    return title && match ? [{ title, topic, topicId: match[1] }] : [];
  });
}

async function fetchTopicImage(item, signal) {
  try {
    const response = await fetch(`/t/${item.topicId}.json`, {
      credentials: "same-origin",
      signal,
    });
    if (!response.ok) {
      return item;
    }
    const data = await response.json();
    const firstPost = data.post_stream?.posts?.find(
      (post) => post.post_number === 1
    );
    if (!firstPost?.cooked) {
      return item;
    }
    const document = new DOMParser().parseFromString(
      firstPost.cooked,
      "text/html"
    );
    const image = document.querySelector(
      "img:not(.emoji):not(.avatar):not(.thumbnail-avatar)"
    );
    return { ...item, image: safeUrl(image?.getAttribute("src"), true) };
  } catch {
    return item;
  }
}

export default class HomepageGroupBuy extends Component {
  @tracked index = 0;
  @tracked items = configuredItems();
  hovering = false;
  focused = false;

  constructor() {
    super(...arguments);
    this.abortController = new AbortController();
    this.loadImages();
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
    this.abortController.abort();
    window.clearInterval(this.timer);
  }

  async loadImages() {
    const items = await Promise.all(
      this.items.map((item) =>
        fetchTopicImage(item, this.abortController.signal)
      )
    );
    if (!this.abortController.signal.aborted) {
      this.items = items;
    }
  }

  get slides() {
    return this.items.map((item, index) => ({
      ...item,
      index,
      position: index + 1,
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
  select(index) {
    this.index = index;
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
        class="moaclab-home-gb {{if this.multiple 'moaclab-home-gb--multiple'}}"
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
              {{#if item.image}}<img src={{item.image}} alt="" />{{/if}}
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
          <div class="moaclab-home-gb__dots" aria-label="选择作品">
            {{#each this.slides as |item|}}
              <button
                class="moaclab-home-gb__dot {{if item.active 'is-active'}}"
                type="button"
                aria-label={{concat "切换到第 " item.position " 个作品"}}
                aria-current={{if item.active "true" "false"}}
                {{on "click" (fn this.select item.index)}}
              ></button>
            {{/each}}
          </div>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
