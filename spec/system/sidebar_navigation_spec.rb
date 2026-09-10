# frozen_string_literal: true

RSpec.describe "Sidebar navigation appearance", system: true do
  let!(:theme) { upload_theme }

  fab!(:category) { Fabricate(:category, name: "Keycaps", icon: "palette", style_type: "icon") }

  before do
    SiteSetting.default_navigation_menu_categories = category.id.to_s
    page.current_window.resize_to(1440, 1000)
  end

  def bounds(selector)
    page.evaluate_script(
      "document.querySelector(#{selector.to_json}).getBoundingClientRect().toJSON()",
    )
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

  it "keeps the native sidebar button on the sidebar boundary in both states" do
    visit("/latest")

    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='true']")
    expect(
      page.evaluate_script(
        "document.querySelector('.btn-sidebar-toggle').getBoundingClientRect().width",
      ),
    ).to eq(32)
    expect(bounds(".btn-sidebar-toggle")["x"]).to eq(232)
    expect(bounds(".home-logo-wrapper-outlet")["x"]).to eq(16)

    find(".btn-sidebar-toggle").click
    expect(page).to have_no_css("body.has-sidebar-page")
    expect(page).to have_no_css(".sidebar-wrapper .sidebar-section-link")
    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='false']")
    expect(bounds(".btn-sidebar-toggle")["x"]).to eq(16)
    expect(bounds(".btn-sidebar-toggle")["y"]).to eq(68)
    divider_content = page.evaluate_script("getComputedStyle(document.body, '::before').content")
    expect(divider_content).to eq('""')
    divider_left = page.evaluate_script("getComputedStyle(document.body, '::before').left")
    expect(divider_left).to eq("31px")
    expect(bounds(".home-logo-wrapper-outlet")["x"]).to eq(16)

    find(".btn-sidebar-toggle").click
    expect(page).to have_css("body.has-sidebar-page")
    expect(page).to have_css(".sidebar-wrapper .sidebar-section-link")
    expect(page).to have_css(".btn-sidebar-toggle[aria-expanded='true']")
    expect(bounds(".btn-sidebar-toggle")["x"]).to eq(232)
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
