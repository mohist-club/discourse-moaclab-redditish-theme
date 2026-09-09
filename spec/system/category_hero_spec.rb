# frozen_string_literal: true

RSpec.describe "Category hero", system: true do
  let!(:theme) { upload_theme }

  fab!(:category) { Fabricate(:category, name: "Keycaps", icon: "palette") }
  fab!(:upload)

  it "shows a background without requiring a logo" do
    category.update!(uploaded_background: upload, description: "Keycap collections")

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__cover img")
    expect(page).to have_css(".moaclab-category-hero__avatar .d-icon-palette")
    expect(page).to have_css(".moaclab-category-hero__name", text: category.name)
    expect(page).to have_css(".moaclab-category-hero__description", text: "Keycap collections")
  end

  it "keeps the name visible when a logo is maintained" do
    category.update!(uploaded_logo: upload)

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-category-hero__avatar img")
    expect(page).to have_no_css(".moaclab-category-hero__cover img")
    expect(page).to have_css(".moaclab-category-hero__name", text: category.name)
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
end
