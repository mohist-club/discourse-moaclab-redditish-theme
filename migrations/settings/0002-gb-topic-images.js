export default function migrate(settings) {
  const items = settings.get("homepage_gb_works");
  if (Array.isArray(items)) {
    settings.set(
      "homepage_gb_works",
      items.map(({ title, topic_url }) => ({ title, topic_url }))
    );
  }
  return settings;
}
