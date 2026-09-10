import Component from "@glimmer/component";
import categoryLink from "discourse/helpers/category-link";
import DLightDarkImg from "discourse/ui-kit/d-light-dark-img";

export default class SidebarSubcategory extends Component {
  get logo() {
    return this.args.category.uploaded_logo?.url
      ? this.args.category.uploaded_logo
      : this.args.category.uploaded_logo_dark;
  }

  <template>
    {{#if this.logo.url}}
      <a
        href={{@category.url}}
        class="badge-category__wrapper moaclab-subcategory-with-logo"
      >
        <span class="badge-category" data-category-id={{@category.id}}>
          <span class="moaclab-subcategory-logo" aria-hidden="true">
            <DLightDarkImg
              @lightImg={{this.logo}}
              @darkImg={{@category.uploaded_logo_dark}}
              alt=""
              loading="lazy"
            />
          </span>
          <span class="badge-category__name">{{@category.displayName}}</span>
        </span>
      </a>
    {{else}}
      {{categoryLink @category}}
    {{/if}}
  </template>
}
