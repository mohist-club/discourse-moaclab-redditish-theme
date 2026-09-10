import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import discoveryFixture from "discourse/tests/fixtures/discovery-fixtures";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const SELECTOR = ".moaclab-home-leaderboard";
let requests;
let response;
let status;

acceptance("Redditish Theme | homepage leaderboard", function (needs) {
  needs.settings({ top_menu: "latest|hot|top|categories" });

  needs.hooks.beforeEach(function () {
    this.savedSettings = {
      enabled: settings.homepage_leaderboard_enabled,
      id: settings.homepage_leaderboard_id,
      count: settings.homepage_leaderboard_count,
    };
    settings.homepage_leaderboard_enabled = true;
    settings.homepage_leaderboard_id = 1;
    settings.homepage_leaderboard_count = 5;
  });

  needs.hooks.afterEach(function () {
    settings.homepage_leaderboard_enabled = this.savedSettings.enabled;
    settings.homepage_leaderboard_id = this.savedSettings.id;
    settings.homepage_leaderboard_count = this.savedSettings.count;
  });

  needs.pretender((server, helper) => {
    requests = 0;
    status = 200;
    response = {
      leaderboard: { id: 1, name: "Community points" },
      users: Array.from({ length: 7 }, (_, index) => ({
        id: index + 1,
        username: `member${index + 1}`,
        avatar_template: "/letter_avatar_proxy/v4/letter/m/ffffff/{size}.png",
        total_score: index < 3 ? 100 - index : 2,
        position: index < 3 ? index + 1 : 4,
      })),
    };

    server.get("/leaderboard/:id.json", () => {
      requests++;
      return helper.response(status, response);
    });
    server.get("/hot.json", () =>
      helper.response(cloneJSON(discoveryFixture["/latest.json"]))
    );
    server.get("/top.json", () =>
      helper.response(cloneJSON(discoveryFixture["/latest.json"]))
    );
  });

  test("shows five members with source ranks and native profile links", async function (assert) {
    await visit("/latest");

    assert.dom(SELECTOR).isVisible();
    assert.dom(`${SELECTOR} h3`).hasText("Community points");
    assert.dom(`${SELECTOR} li`).exists({ count: 5 });
    assert.dom(`${SELECTOR} .avatar`).exists({ count: 5 });
    assert
      .dom(`${SELECTOR} li:first-child a`)
      .hasAttribute("href", "/u/member1");
    assert
      .dom(`${SELECTOR} li:first-child a`)
      .hasAttribute("data-user-card", "member1");
    assert
      .dom(`${SELECTOR} li:last-child .moaclab-home-leaderboard__rank`)
      .hasText("4");
    assert
      .dom(".moaclab-home-leaderboard__more")
      .hasAttribute("href", "/leaderboard/1");
  });

  test("does not fetch on other lists and reuses the homepage cache", async function (assert) {
    await visit("/hot");
    assert.dom(SELECTOR).doesNotExist();
    assert.strictEqual(requests, 0);
    await visit("/latest");
    await visit("/top");
    assert.dom(SELECTOR).doesNotExist();
    await visit("/latest");
    assert.dom(SELECTOR).isVisible();
    assert.strictEqual(requests, 1);
  });

  test("does not fetch when the switch is off", async function (assert) {
    settings.homepage_leaderboard_enabled = false;
    await visit("/latest");
    assert.dom(SELECTOR).doesNotExist();
    assert.strictEqual(requests, 0);
  });

  test("uses the configured homepage, board and member count", async function (assert) {
    this.siteSettings.top_menu = "hot|latest|top";
    settings.homepage_leaderboard_id = 2;
    settings.homepage_leaderboard_count = 3;
    response.leaderboard.id = 2;
    await visit("/latest");
    assert.dom(SELECTOR).doesNotExist();
    await visit("/hot");
    assert.dom(`${SELECTOR} li`).exists({ count: 3 });
    assert
      .dom(".moaclab-home-leaderboard__more")
      .hasAttribute("href", "/leaderboard/2");
  });

  test("hides empty or malformed boards", async function (assert) {
    response.users = [{ username: "invalid" }];
    await visit("/latest");
    assert.dom(SELECTOR).isNotVisible();
    assert.dom(`${SELECTOR} li`).doesNotExist();
  });

  [403, 404, 500].forEach((errorStatus) => {
    test(`hides unavailable boards (${errorStatus}) without repeated requests`, async function (assert) {
      status = errorStatus;
      response = { errors: ["Unavailable"] };
      await visit("/latest");
      assert.dom(SELECTOR).isNotVisible();
      await visit("/hot");
      await visit("/latest");
      assert.strictEqual(requests, 1);
    });
  });

  test("refreshes after the cache expires", async function (assert) {
    await visit("/latest");
    const cache = this.container.lookup("service:moaclab-leaderboard").cache;
    for (const entry of cache.values()) {
      entry.expiresAt = 0;
    }
    await visit("/hot");
    await visit("/latest");
    assert.strictEqual(requests, 2);
  });
});
