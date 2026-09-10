import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DMenu from "discourse/float-kit/components/d-menu";
import icon from "discourse/helpers/d-icon";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { NotificationLevels } from "discourse/lib/notification-levels";
import Composer from "discourse/models/composer";
import CategoryNotificationsButton from "discourse/select-kit/components/category-notifications-button";
import { i18n } from "discourse-i18n";
import AddToSidebar from "./add-to-sidebar";

export default class CategoryHeroActions extends Component {
  @service currentUser;
  @service composer;

  get notificationLevel() {
    return this.currentUser?.indirectly_muted_category_ids?.includes(
      this.args.category.id
    )
      ? NotificationLevels.MUTED
      : this.args.category.notification_level;
  }

  get feedUrl() {
    return `${this.args.category.url}.rss`;
  }

  @action
  async changeNotificationLevel(level) {
    try {
      await this.args.category.setNotification(level);
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  createTopic() {
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
      categoryId: this.args.category.id,
    });
  }

  <template>
    <div class="moaclab-category-hero__actions">
      {{#if this.currentUser}}
        {{#if @category.canCreateTopic}}
          <DButton
            class="btn-default moaclab-category-create"
            @action={{this.createTopic}}
            @icon="plus"
            @label="topic.create"
          />
        {{/if}}
        <CategoryNotificationsButton
          @value={{this.notificationLevel}}
          @category={{@category}}
          @onChange={{this.changeNotificationLevel}}
        />
        <AddToSidebar @category={{@category}} @showLabel={{true}} />
      {{/if}}

      <DMenu
        class="btn-default moaclab-category-more"
        @icon="ellipsis"
        @title={{i18n "more"}}
        @identifier="moaclab-category-more-menu"
      >
        <:content>
          <div class="moaclab-category-menu">
            {{#if @category.topic_url}}
              <a href={{@category.topic_url}}>
                {{icon "circle-info"}}
                {{i18n (themePrefix "about_category")}}
              </a>
            {{/if}}
            <a href={{this.feedUrl}}>
              {{icon "rss"}}
              {{i18n (themePrefix "category_rss")}}
            </a>
          </div>
        </:content>
      </DMenu>
    </div>
  </template>
}
