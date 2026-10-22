import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { getOwner } from "@ember/owner";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";
import DMenu from "discourse/float-kit/components/d-menu";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Composer from "discourse/models/composer";
import TagNotificationsButton from "discourse/select-kit/components/tag-notifications-button";
import { i18n } from "discourse-i18n";
import AddToSidebar from "./add-to-sidebar";

export default class CustomTagBanner extends Component {
  @service router;
  @service store;
  @service currentUser;
  @service composer;

  @tracked tagInfo = null;
  @tracked tagNotification = null;
  requestId = 0;

  get category() {
    return this.router.currentRoute?.attributes?.category;
  }

  get tag() {
    return this.router.currentRoute?.attributes?.tag;
  }

  get showHero() {
    return (
      this.tag?.id &&
      this.tag.name !== "none" &&
      !this.category &&
      !this.router.currentRoute?.attributes?.additionalTags?.length
    );
  }

  get topicCount() {
    const count = this.tagInfo?.topic_count;
    return Number.isFinite(count)
      ? i18n(themePrefix("tag_topic_count"), { count })
      : null;
  }

  @action
  async loadTag() {
    const requestId = ++this.requestId;
    const tagId = this.tag?.id;
    this.tagInfo = null;
    this.tagNotification = null;
    if (!this.showHero) {
      return;
    }

    // Route changes must not display the previous tag's count or notification state.
    const [info, notification] = await Promise.allSettled([
      this.store.find("tag-info", tagId),
      this.currentUser
        ? this.store.find("tagNotification", tagId)
        : Promise.resolve(null),
    ]);
    if (
      this.isDestroying ||
      requestId !== this.requestId ||
      this.tag?.id !== tagId
    ) {
      return;
    }
    if (info.status === "fulfilled") {
      this.tagInfo = info.value;
    }
    if (notification.status === "fulfilled") {
      this.tagNotification = notification.value;
    }
  }

  @action
  async changeNotificationLevel(level) {
    const notification = this.tagNotification;
    if (!notification) {
      return;
    }
    try {
      const response = await notification.update({ notification_level: level });
      notification.set("notification_level", level);
      const payload = response.responseJson;
      this.currentUser.setProperties({
        watched_tags: payload.watched_tags,
        watching_first_post_tags: payload.watching_first_post_tags,
        tracked_tags: payload.tracked_tags,
        muted_tags: payload.muted_tags,
        regular_tags: payload.regular_tags,
      });
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  createTopic() {
    this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
      tags: [this.tag.name],
    });
  }

  @action
  async editTag(closeMenu) {
    await closeMenu();
    this.router.transitionTo(
      "tag.edit.tab",
      this.tag.slug,
      this.tag.id,
      "general"
    );
  }

  @action
  async toggleInfo(closeMenu) {
    await closeMenu();
    getOwner(this).lookup("controller:tag.show").toggleTagInfo();
  }

  <template>
    {{#if this.showHero}}
      <section
        class="custom-tag-banner moaclab-tag-hero"
        aria-labelledby="moaclab-tag-title"
        {{didInsert this.loadTag}}
        {{didUpdate this.loadTag this.tag.id}}
      >
        <div class="moaclab-tag-hero__identity">
          <h1 id="moaclab-tag-title">
            <span class="moaclab-tag-hero__icon" aria-hidden="true"></span>
            <a href={{this.tag.url}}>{{this.tag.name}}</a>
          </h1>
          {{#if this.topicCount}}
            <p class="moaclab-tag-hero__count">{{this.topicCount}}</p>
          {{/if}}
          {{#if this.tagInfo.description}}
            <div class="moaclab-tag-hero__description">
              {{#if this.tagInfo.description_cooked}}
                {{htmlSafe this.tagInfo.description_cooked}}
              {{else}}
                {{this.tagInfo.description}}
              {{/if}}
            </div>
          {{/if}}
        </div>
        <div class="moaclab-tag-hero__actions">
          {{#if this.currentUser}}
            {{#if this.currentUser.can_create_topic}}
              <DButton
                class="btn-default moaclab-tag-create"
                @action={{this.createTopic}}
                @icon="plus"
                @label="topic.create"
              />
            {{/if}}
            {{#if this.tagNotification}}
              <TagNotificationsButton
                @onChange={{this.changeNotificationLevel}}
                @value={{this.tagNotification.notification_level}}
              />
            {{/if}}
            <AddToSidebar @tag={{this.tag}} />
          {{/if}}
          <DMenu
            class="btn-default moaclab-tag-more"
            @icon="ellipsis"
            @title={{i18n "more"}}
            @identifier="moaclab-tag-more-menu"
          >
            <:content as |menu|>
              <div class="moaclab-tag-menu">
                <DButton
                  @action={{fn this.toggleInfo menu.close}}
                  @icon="circle-info"
                  @translatedLabel={{i18n (themePrefix "about_tag")}}
                />
                {{#if this.currentUser.canEditTags}}
                  <DButton
                    @action={{fn this.editTag menu.close}}
                    @icon="wrench"
                    @label="tagging.edit"
                  />
                {{/if}}
              </div>
            </:content>
          </DMenu>
        </div>
      </section>
    {{/if}}
  </template>
}
