# frozen_string_literal: true

RSpec.describe "Category hero", system: true do
  let!(:theme) { upload_theme }

  fab!(:category) { Fabricate(:category, name: "Keycaps", icon: "palette") }
  fab!(:upload)

  before { page.current_window.resize_to(1440, 1000) }

  it "shows a background without requiring a logo" do
    category.update!(uploaded_background: upload, description: "Keycap collections")

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__cover img")
    expect(
      page.evaluate_script(
        "document.querySelector('.moaclab-category-hero__cover').getBoundingClientRect().height",
      ),
    ).to eq(160)
    expect(page).to have_css(".moaclab-category-hero__avatar .d-icon-palette")
    expect(page).to have_css(".moaclab-category-hero__name", text: category.name)
    expect(page).to have_no_css(".moaclab-category-hero__description")
    expect(page).to have_css(".moaclab-category-about__description", text: "Keycap collections")
  end

  it "keeps the name visible when a logo is maintained" do
    category.update!(uploaded_logo: upload)

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__avatar img")
    expect(page).to have_no_css(".moaclab-category-hero__cover img")
    expect(page).to have_css(".moaclab-category-hero__name", text: category.name)
    expect(
      page.evaluate_script(
        "document.querySelector('.moaclab-category-hero__cover').getBoundingClientRect().height",
      ),
    ).to eq(64)

    page.current_window.resize_to(390, 844)
    expect(
      page.evaluate_script(
        "document.querySelector('.moaclab-category-hero__cover').getBoundingClientRect().height",
      ),
    ).to eq(48)
  end

  it "uses dark-only images when no light variant exists" do
    category.update!(uploaded_logo_dark: upload, uploaded_background_dark: upload)

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__avatar img")
    expect(page).to have_css(".moaclab-category-hero__cover img")
    expect(page).to have_css(".moaclab-category-hero__name", text: category.name)
  end

  it "falls back to the category initial and does not add a hero on the homepage" do
    category.update!(icon: nil, emoji: nil)

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__avatar", text: "K")
    expect(page).to have_no_css(".moaclab-category-hero__cover img")

    visit("/latest")

    expect(page).to have_no_css(".moaclab-category-hero")
  end

  it "opens a native more menu and keeps the description visible on narrow screens" do
    category.update!(description: "Keycap collections")
    visit("/c/#{category.slug}/#{category.id}")

    find(".moaclab-category-more").click
    expect(page).to have_css(".moaclab-category-menu a[href$='.rss']")
    page.send_keys(:escape)
    expect(page).to have_no_css(".moaclab-category-menu")

    page.current_window.resize_to(390, 844)
    expect(page).to have_css(".moaclab-category-hero__description", text: "Keycap collections")
    expect(page).to have_css(".moaclab-category-more")
    fits_viewport = page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
    expect(fits_viewport).to eq(true)
  end

  it "uses native creation, notification and saved-category actions in the hero" do
    user = Fabricate(:user)
    sign_in(user)
    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__actions .moaclab-category-create")
    old_controls = ".custom-right-sidebar_category-about .category-notifications-button"
    expect(page).to have_no_css(old_controls)
    find(".moaclab-category-hero__actions .category-notifications-button").click
    expect(page).to have_css(".category-notifications-button.is-expanded")
    page.send_keys(:escape)

    saved_button = find(".moaclab-category-hero__actions .add-to-sidebar")
    saved_before = saved_button["aria-pressed"] == "true"
    saved_button.click
    expect(page).to have_css(".add-to-sidebar[aria-pressed='#{!saved_before}']")
    try_until_success do
      saved_ids = user.secured_sidebar_category_ids
      expect(saved_ids.include?(category.id)).to eq(!saved_before)
    end

    find(".moaclab-category-create").click
    expect(page).to have_css("#reply-control.open")
    expect(page).to have_css("#reply-control .category-chooser .selected-name", text: category.name)
  end
end
