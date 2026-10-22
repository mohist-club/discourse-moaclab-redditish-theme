import { find, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import discoveryFixture from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Redditish Theme | tag routes", function (needs) {
  needs.settings({ tagging_enabled: true });
  needs.user({
    can_create_topic: true,
    sidebar_tags: [],
    sidebar_category_ids: [],
  });

  needs.pretender((server, helper) => {
    server.get("/tag/1/info.json", () => {
      return helper.response({
        tag_info: {
          id: 1,
          name: "important",
          slug: "important",
          description: "Important topics for discussion",
          topic_count: 5,
          pm_only: false,
        },
        categories: [],
        tag_group_names: [],
      });
    });

    server.get("/tag/1/l/latest.json", () => {
      return helper.response(
        cloneJSON(discoveryFixture["/tag/important/l/latest.json"])
      );
    });

    server.get("/tag/1/notifications.json", () => {
      return helper.response({
        tag_notification: {
          id: 1,
          notification_level: 1,
        },
      });
    });
  });

  test("displays tag banner with tag name", async function (assert) {
    await visit("/tag/important/1");

    assert
      .dom(".custom-tag-banner h1")
      .hasText("important", "tag banner displays the tag name");
    assert.dom(".moaclab-tag-hero__count").hasText("5 topics");
    assert
      .dom(".moaclab-tag-hero__description")
      .hasText("Important topics for discussion");
    assert.dom(".moaclab-tag-hero__actions .moaclab-tag-create").exists();
    assert.dom(".moaclab-tag-hero__actions .add-to-sidebar").exists();
    assert.dom(".custom-right-sidebar_tag-about").doesNotExist();
    const trigger = find(
      ".moaclab-tag-hero .tag-notifications-button .select-kit-header"
    ).getBoundingClientRect();
    const bell = find(
      ".moaclab-tag-hero .tag-notifications-button .select-kit-header .d-icon"
    ).getBoundingClientRect();
    assert.true(
      Math.abs(bell.x + bell.width / 2 - trigger.x - trigger.width / 2) < 0.5,
      "notification bell is horizontally centered"
    );
    assert.true(
      Math.abs(bell.y + bell.height / 2 - trigger.y - trigger.height / 2) < 0.5,
      "notification bell is vertically centered"
    );
  });
});
