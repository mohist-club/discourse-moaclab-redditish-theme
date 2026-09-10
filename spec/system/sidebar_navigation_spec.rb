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
    divider_z = page.evaluate_script("getComputedStyle(document.body, '::before').zIndex")
    expect(divider_z.to_i).to be > 0
    divider_height = page.evaluate_script("getComputedStyle(document.body, '::before').height")
    expect(divider_height).to eq("944px")
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

  it "insets rounded selected rows and separates titled sections" do
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_css(".sidebar-wrapper .sidebar-section-link.active")

    appearance = page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector('.sidebar-wrapper');
        const selected = sidebar.querySelector('.sidebar-section-link.active');
        const style = getComputedStyle(selected);
        const sections = [...sidebar.querySelectorAll('.sidebar-section-header-wrapper')];
        return {
          inset: selected.getBoundingClientRect().left - sidebar.getBoundingClientRect().left,
          radius: [style.borderTopLeftRadius, style.borderBottomLeftRadius,
                   style.borderTopRightRadius, style.borderBottomRightRadius],
          dividers: sections.map(row => getComputedStyle(row.parentElement).borderTopWidth)
        };
      })()
    JS
    expect(appearance["inset"]).to be >= 12
    expect(appearance["radius"]).to eq(%w[8px 8px 8px 8px])
    expect(appearance["dividers"]).to all(eq("1px"))
  end

  it "aligns carets at the right edge without blocking native admin controls" do
    sign_in(Fabricate(:admin))
    visit("/latest")
    expect(page).to have_css(".sidebar-section-header-button", visible: :all)

    layout = page.evaluate_script(<<~JS)
      (() => {
        const rows = [...document.querySelectorAll('.sidebar-wrapper .sidebar-section-header-wrapper')];
        return rows.filter(row => row.querySelector('.sidebar-section-header-caret')).map(row => {
          const caret = row.querySelector('.sidebar-section-header-caret').getBoundingClientRect();
          const actions = row.querySelectorAll('.sidebar-section-header-button, .sidebar-section-header-dropdown');
          return {
            inset: row.getBoundingClientRect().right - caret.right,
            overlap: [...actions].some(button => button.getBoundingClientRect().right > caret.left)
          };
        });
      })()
    JS
    expect(layout).not_to be_empty
    expect(layout.map { |row| row["inset"] }).to all(be_within(1).of(8))
    expect(layout.map { |row| row["overlap"] }).to all(eq(false))

    section = ".sidebar-wrapper [data-section-name='categories']"
    find("#{section} .sidebar-section-header-caret").click
    expect(page).to have_css("#{section} .sidebar-section-header[aria-expanded='false']")
    find("#{section} .sidebar-section-header-caret").click
    expect(page).to have_css("#{section} .sidebar-section-header[aria-expanded='true']")
  end
end
