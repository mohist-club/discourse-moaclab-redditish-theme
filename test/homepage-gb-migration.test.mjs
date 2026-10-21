import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const source = await readFile(
  new URL("../migrations/settings/0001-migrate-homepage-gb.js", import.meta.url),
  "utf8"
);
const { default: migrate } = await import(
  `data:text/javascript;base64,${Buffer.from(source).toString("base64")}`
);

test("migrates list and separate single work", () => {
  const settings = new Map([
    ["homepage_gb_items", JSON.stringify([{ title: "A", image_url: "https://example.com/a.jpg", topic_url: "/t/a/1" }])],
    ["homepage_gb_title", "B"],
    ["homepage_gb_image_url", "https://example.com/b.jpg"],
    ["homepage_gb_topic_url", "/t/b/2"],
  ]);
  migrate(settings);
  assert.deepEqual(settings.get("homepage_gb_works"), [
    { title: "A", image_url: "https://example.com/a.jpg", topic_url: "/t/a/1" },
    { title: "B", image_url: "https://example.com/b.jpg", topic_url: "/t/b/2" },
  ]);
  assert.equal(settings.has("homepage_gb_title"), false);
});

test("rejects broken JSON or incomplete single work without deleting settings", () => {
  for (const input of [
    [["homepage_gb_items", "broken"]],
    [["homepage_gb_title", "unfinished"]],
  ]) {
    const settings = new Map(input);
    assert.throws(() => migrate(settings));
    assert.deepEqual([...settings], input);
  }
});
