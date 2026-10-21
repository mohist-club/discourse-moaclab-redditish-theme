export default function migrate(settings) {
  const oldKeys = [
    "homepage_gb_items",
    "homepage_gb_title",
    "homepage_gb_image_url",
    "homepage_gb_topic_url",
  ];
  const raw = settings.get("homepage_gb_items");
  let items = [];
  if (raw && raw.trim()) {
    items = JSON.parse(raw);
    if (!Array.isArray(items)) {
      throw new Error(
        "Homepage GB items must be a JSON array before migration"
      );
    }
  }

  const legacy = {
    title: settings.get("homepage_gb_title") || "",
    image_url: settings.get("homepage_gb_image_url") || "",
    topic_url: settings.get("homepage_gb_topic_url") || "",
  };
  if (Object.values(legacy).some((value) => value.trim())) {
    if (!Object.values(legacy).every((value) => value.trim())) {
      throw new Error(
        "Complete or clear the old homepage GB fields before migration"
      );
    }
    if (
      !items.some(
        (item) =>
          item?.title === legacy.title && item?.topic_url === legacy.topic_url
      )
    ) {
      items.push(legacy);
    }
  }

  if (items.length) {
    settings.set(
      "homepage_gb_works",
      items.map((item) => ({
        title: item.title,
        image_url: item.image_url,
        topic_url: item.topic_url,
      }))
    );
  }
  oldKeys.forEach((key) => settings.delete(key));
  return settings;
}
