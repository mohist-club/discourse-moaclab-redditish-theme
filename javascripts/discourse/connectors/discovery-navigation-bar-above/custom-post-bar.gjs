import Component from "@glimmer/component";
import { service } from "@ember/service";
import FakeInputCreate from "../../components/fake-input-create";

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

  <template>
    {{#if this.showPostBar}}
      <div class="discovery-navigation-bar-above-outlet custom-post-bar">
        <FakeInputCreate />
      </div>
    {{/if}}
  </template>
}
