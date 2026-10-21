/* eslint-disable ember/no-classic-components */
import Component from "@ember/component";
import { service } from "@ember/service";
import { tagName } from "@ember-decorators/component";
import CustomCategoryBanner0 from "../../components/custom-category-banner";
import CustomTagBanner from "../../components/custom-tag-banner";
import HomepageGroupBuy from "../../components/homepage-group-buy";

@tagName("")
export default class CustomCategoryBannerConnector extends Component {
  @service router;
  @service siteSettings;

  get showGroupBuy() {
    const homepage = this.siteSettings.top_menu.split("|")[0];
    return (
      settings.homepage_gb_enabled &&
      this.router.currentRouteName === `discovery.${homepage}`
    );
  }

  <template>
    <CustomCategoryBanner0 />
    <CustomTagBanner />
    {{#if this.showGroupBuy}}
      <HomepageGroupBuy />
    {{/if}}
  </template>
}
