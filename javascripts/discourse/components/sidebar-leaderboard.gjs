import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import avatar from "discourse/helpers/avatar";
import getURL from "discourse/lib/get-url";
import { not } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class SidebarLeaderboard extends Component {
  @service router;
  @service siteSettings;
  @service moaclabLeaderboard;

  @tracked result = null;

  get shouldShow() {
    const homepage = this.siteSettings.top_menu.split("|")[0];
    return (
      settings.homepage_leaderboard_enabled &&
      this.router.currentRouteName === `discovery.${homepage}`
    );
  }

  get leaderboardId() {
    return Number(settings.homepage_leaderboard_id);
  }

  get title() {
    return this.result?.name || i18n(themePrefix("leaderboard_title"));
  }

  get url() {
    return getURL(`/leaderboard/${this.leaderboardId}`);
  }

  get users() {
    if (this.result?.id !== this.leaderboardId) {
      return [];
    }

    const limit = Math.max(
      1,
      Math.min(10, Number(settings.homepage_leaderboard_count) || 5)
    );
    return this.result.users.slice(0, limit).map((user) => ({
      ...user,
      url: getURL(`/u/${encodeURIComponent(user.username.toLowerCase())}`),
      rankLabel: i18n(themePrefix("leaderboard_rank"), {
        rank: user.position,
      }),
    }));
  }

  @action
  async load() {
    const id = this.leaderboardId;
    const result = await this.moaclabLeaderboard.load(id);
    if (
      !this.isDestroying &&
      !this.isDestroyed &&
      this.shouldShow &&
      id === this.leaderboardId
    ) {
      this.result = result;
    }
  }

  <template>
    {{#if this.shouldShow}}
      <section
        class="moaclab-home-leaderboard"
        aria-label={{this.title}}
        hidden={{not this.users.length}}
        {{didInsert this.load}}
        {{didUpdate this.load this.leaderboardId}}
      >
        <header class="moaclab-home-leaderboard__header">
          <h3>{{this.title}}</h3>
          <span>{{i18n (themePrefix "leaderboard_score")}}</span>
        </header>
        <ol class="moaclab-home-leaderboard__list">
          {{#each this.users as |user|}}
            <li>
              <a href={{user.url}} data-user-card={{user.username}}>
                <span
                  class="moaclab-home-leaderboard__rank"
                  aria-label={{user.rankLabel}}
                >{{user.position}}</span>
                {{avatar user imageSize="small"}}
                <span
                  class="moaclab-home-leaderboard__username"
                  title={{user.username}}
                >{{user.username}}</span>
                <span
                  class="moaclab-home-leaderboard__score"
                >{{user.total_score}}</span>
              </a>
            </li>
          {{/each}}
        </ol>
        <a class="moaclab-home-leaderboard__more" href={{this.url}}>
          {{i18n (themePrefix "leaderboard_view_all")}}
        </a>
      </section>
    {{/if}}
  </template>
}
