# frozen_string_literal: true

RSpec.describe "Header search compatibility", system: true do
  let!(:theme) { upload_theme }
  fab!(:category) { Fabricate(:category, name: "Keyboard collections") }

  before do
    search_settings = { theme_id: theme.id, name: "search_experience", value: "search_field" }
    Themes::ThemeSiteSettingManager.call(
      guardian: Fabricate(:admin).guardian,
      params: search_settings,
    )
    page.current_window.resize_to(1440, 1000)
  end

  it "keeps one search field when a legacy connector is also installed" do
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_css("#header-search-input")

    search_style = page.evaluate_script(<<~JS)
      (() => {
        const input = document.querySelector('#header-search-input');
        const style = getComputedStyle(input.closest('.search-input-wrapper'));
        return { background: style.backgroundColor, border: style.borderTopWidth };
      })()
    JS
    expect(search_style["background"]).to eq("rgba(0, 0, 0, 0)")
    expect(search_style["border"]).to eq("1px")

    page.execute_script(<<~JS)
      const wrapper = document.querySelector('.d-header .contents > .floating-search-input-wrapper');
      const legacy = wrapper.cloneNode(true);
      legacy.querySelector('input').id = 'advanced-header-search-input';
      document.querySelector('.before-header-panel-outlet').append(legacy);
    JS

    expect(page).to have_css(".d-header input[type='search']", count: 1)
    expect(page).to have_no_css("#advanced-header-search-input")
    expect(
      page.evaluate_script(
        "document.querySelector('#header-search-input').getBoundingClientRect().height",
      ),
    ).to eq(40)

    fill_in("header-search-input", with: "keyboard")
    expect(page).to have_css(".search-menu-panel")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('#header-search-input').parentElement).outlineStyle",
      ),
    ).to eq("none")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('#header-search-input')).outlineStyle",
      ),
    ).to eq("none")
    expect(
      page.evaluate_script(
        "getComputedStyle(document.querySelector('#header-search-input').closest('.search-input-wrapper')).boxShadow",
      ),
    ).not_to eq("none")

    page.execute_script(
      "document.querySelector('.d-header .contents > .floating-search-input-wrapper').remove()",
    )
    expect(page).to have_css("#advanced-header-search-input")
  end

  it "keeps the search inside the viewport on narrow desktop screens" do
    page.current_window.resize_to(1024, 900)
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_css("#header-search-input")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to eq(true)
    expect(
      page.evaluate_script(
        "document.querySelector('#header-search-input').getBoundingClientRect().width",
      ),
    ).to be > 100
  end

  it "separates the fixed header with a line instead of a shadow" do
    visit("/c/#{category.slug}/#{category.id}")
    find(".d-header").hover

    appearance = page.evaluate_script(<<~JS)
      (() => {
        const style = getComputedStyle(document.querySelector('.d-header'));
        return { border: style.borderBottomWidth, borderStyle: style.borderBottomStyle,
                 shadow: style.boxShadow, position: style.position };
      })()
    JS
    expect(appearance["border"]).to eq("1px")
    expect(appearance["borderStyle"]).to eq("solid")
    expect(appearance["shadow"]).to eq("none")
    expect(appearance["position"]).to eq("fixed")
  end
end
