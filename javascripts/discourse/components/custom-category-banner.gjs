import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import icon from "discourse/helpers/d-icon";
import emoji from "discourse/helpers/emoji";
import DLightDarkImg from "discourse/ui-kit/d-light-dark-img";
import CategoryHeroActions from "./category-hero-actions";

export default class CustomCategoryBanner extends Component {
  @service router;

  get category() {
    if (this.args.category) {
      return this.args.category;
    }

    let route = this.router.currentRoute;
    while (route) {
      if (route.attributes?.category) {
        return route.attributes.category;
      }
      route = route.parent;
    }
    return null;
  }

  get background() {
    return (
      this.category?.uploaded_background ||
      this.category?.uploaded_background_dark
    );
  }

  get logo() {
    return this.category?.uploaded_logo || this.category?.uploaded_logo_dark;
  }

  get categoryStyle() {
    const color = this.category?.color;
    return /^[0-9a-f]{6}$/i.test(color || "")
      ? htmlSafe(`--moaclab-category-accent: #${color};`)
      : undefined;
  }

  get categoryName() {
    return this.category?.displayName || this.category?.name;
  }

  get description() {
    return this.category?.descriptionText || this.category?.description_text;
  }

  get categoryEmoji() {
    return this.category?.style_type === "emoji" ? this.category.emoji : null;
  }

  get categoryInitial() {
    return Array.from(this.categoryName || "")[0];
  }

  <template>
    {{#if this.category}}
      <section
        class="custom-category-banner moaclab-category-hero"
        style={{this.categoryStyle}}
        aria-label={{this.categoryName}}
      >
        <div class="moaclab-category-hero__cover" aria-hidden="true">
          {{#if this.background.url}}
            <DLightDarkImg
              @lightImg={{this.background}}
              @darkImg={{this.category.uploaded_background_dark}}
              alt=""
              loading="eager"
            />
          {{/if}}
        </div>

        <div class="moaclab-category-hero__identity">
          <div class="moaclab-category-hero__avatar" aria-hidden="true">
            {{#if this.logo.url}}
              <DLightDarkImg
                @lightImg={{this.logo}}
                @darkImg={{this.category.uploaded_logo_dark}}
                alt=""
              />
            {{else if this.categoryEmoji}}
              {{emoji this.categoryEmoji}}
            {{else if this.category.icon}}
              {{icon this.category.icon}}
            {{else}}
              <span>{{this.categoryInitial}}</span>
            {{/if}}
          </div>

          <h1 class="moaclab-category-hero__name">{{this.categoryName}}</h1>
          <CategoryHeroActions @category={{this.category}} />
        </div>

        {{#if this.description}}
          <p class="moaclab-category-hero__description">{{this.description}}</p>
        {{/if}}
      </section>
    {{/if}}
  </template>
}
