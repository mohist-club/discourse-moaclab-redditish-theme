import Component from "@glimmer/component";
import { service } from "@ember/service";
import FakeInputCreate from "../../components/fake-input-create";
import HomepageGroupBuy from "../../components/homepage-group-buy";

export default class CustomPostBar extends Component {
  @service router;
  @service siteSettings;
  @service currentUser;

  get showPostBar() {
    const homepage = this.siteSettings.top_menu.split("|")[0];
    return (
      this.currentUser?.can_create_topic &&
      this.router.currentRouteName === `discovery.${homepage}`
    );
  }

  get showGroupBuy() {
    const homepage = this.siteSettings.top_menu.split("|")[0];
    return (
      settings.homepage_gb_enabled &&
      this.router.currentRouteName === `discovery.${homepage}`
    );
  }

  <template>
    {{#if this.showGroupBuy}}
      <HomepageGroupBuy />
    {{/if}}
    {{#if this.showPostBar}}
      <div class="discovery-navigation-bar-above-outlet custom-post-bar">
        <FakeInputCreate />
      </div>
    {{/if}}
  </template>
}
