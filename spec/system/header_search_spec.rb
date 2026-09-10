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
end
