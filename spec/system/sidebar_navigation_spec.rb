# frozen_string_literal: true

RSpec.describe "Sidebar navigation appearance", system: true do
  let!(:theme) { upload_theme }

  fab!(:category) { Fabricate(:category, name: "Keycaps", icon: "palette", style_type: "icon") }

  before do
    SiteSetting.default_sidebar_categories = category.id.to_s
    page.current_window.resize_to(1440, 1000)
  end

  it "uses an outline for neutral category icons and the native glyph when selected" do
    visit("/latest")

    expect(page).to have_css(".sidebar-wrapper .d-icon-palette", visible: :all)
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.sidebar-wrapper .d-icon-palette')).visibility",
      ),
    ).to eq("hidden")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.sidebar-wrapper .d-icon-palette').parentElement, '::before').maskImage",
      ),
    ).not_to eq("none")

    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".sidebar-wrapper .d-icon-palette", visible: true)
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('.sidebar-wrapper .d-icon-palette').parentElement, '::before').display",
      ),
    ).to eq("none")
  end

  it "keeps the native sidebar button working at the boundary and in the header" do
    visit("/latest")

    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='true']")
    expect(
      page.evaluate_script(
        "document.querySelector('.btn-sidebar-toggle').getBoundingClientRect().width",
      ),
    ).to eq(32)

    find(".btn-sidebar-toggle").click
    expect(page).to have_no_css(".sidebar-wrapper")
    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='false']")

    find(".btn-sidebar-toggle").click
    expect(page).to have_css(".sidebar-wrapper")
    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='true']")
  end

  it "closes the mobile drawer with Escape and releases scrolling" do
    page.current_window.resize_to(390, 844)
    visit("/latest")

    find(".hamburger-dropdown").click
    expect(page).to have_css(".sidebar-hamburger-dropdown")

    page.send_keys(:escape)

    expect(page).to have_no_css(".sidebar-hamburger-dropdown")
    expect(page).to have_no_css("html.scroll-lock")
    expect(page).to have_css("#toggle-hamburger-menu:focus")
  end
end
