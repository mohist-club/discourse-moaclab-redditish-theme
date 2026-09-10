import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import categoryLink from "discourse/helpers/category-link";
import icon from "discourse/helpers/d-icon";
import { getCategoryAndTagUrl } from "discourse/lib/url";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class SidebarAboutCategory extends Component {
  @service site;
  @service router;
  @service currentUser;

  get category() {
    let route = this.router.currentRoute;
    while (route) {
      if (route.attributes?.category) {
        return route.attributes.category;
      }
      route = route.parent;
    }
    return null;
  }

  get topTags() {
    return (this.site.categoryTopTags || []).map((tag) => ({
      name: tag.name,
      href: getCategoryAndTagUrl(this.category, true, tag),
    }));
  }

  get hasCounts() {
    return Number.isFinite(this.category?.topic_count);
  }

  get linkedDescription() {
    return i18n(themePrefix("about_category_admin_tip_description"), {
      topicUrl: this.category.topic_url,
    });
  }

  <template>
    {{#if this.category}}
      <div class="custom-right-sidebar_category-about">
        <h3 class="moaclab-category-about__name">
          {{this.category.displayName}}
        </h3>
        {{#if this.category.description}}
          <div class="moaclab-category-about__description">
            {{htmlSafe this.category.description}}
          </div>
        {{else}}
          {{#if this.currentUser.admin}}
            <h3>{{i18n (themePrefix "about_admin_tip_headline")}}</h3>
            <p>
              {{htmlSafe this.linkedDescription}}
            </p>
          {{/if}}
        {{/if}}
        <div class="moaclab-category-about__visibility">
          {{#if this.category.read_restricted}}
            {{icon "lock"}}
            {{i18n (themePrefix "category_private")}}
          {{else}}
            {{icon "globe"}}
            {{i18n (themePrefix "category_public")}}
          {{/if}}
        </div>
        {{#if this.hasCounts}}
          <dl class="moaclab-category-about__stats">
            <div>
              <dt>{{i18n (themePrefix "category_topics")}}</dt>
              <dd>{{this.category.topic_count}}</dd>
            </div>
            <div>
              <dt>{{i18n (themePrefix "category_posts")}}</dt>
              <dd>{{this.category.post_count}}</dd>
            </div>
          </dl>
        {{/if}}

      </div>
      {{#if (or this.category.subcategories this.topTags.length)}}

        <div
          class="custom-right-sidebar_category-about -tags-and-subcategories"
        >

          {{#if this.category.subcategories}}
            <div class="custom-right-sidebar_subcategories">
              <h4>{{i18n (themePrefix "subcategories")}}</h4>
              {{#each this.category.subcategories as |subcategory|}}
                {{categoryLink subcategory}}
              {{/each}}
            </div>
          {{/if}}

          {{#if this.topTags.length}}
            <div class="custom-right-sidebar_tags">
              <h4>{{i18n (themePrefix "top_tags")}}</h4>
              <div class="discourse-tags">
                {{#each this.topTags as |tag|}}
                  <a
                    href={{tag.href}}
                    data-tag-name={{tag.name}}
                    class="discourse-tag simple"
                  >
                    {{tag.name}}
                  </a>
                {{/each}}
              </div>
            </div>
          {{/if}}
        </div>
      {{/if}}
    {{/if}}
  </template>
}
