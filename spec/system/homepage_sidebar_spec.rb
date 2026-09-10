# frozen_string_literal: true

RSpec.describe "Homepage sidebar", system: true do
  let!(:theme) { upload_theme }

  before do
    SiteSetting.top_menu = "latest|hot|top"
    12.times { Fabricate(:post) }
    page.current_window.resize_to(1440, 700)
  end

  it "keeps the complete right column in place while the homepage scrolls" do
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome")

    initial = page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector('.custom-right-sidebar');
        const style = getComputedStyle(sidebar);
        const rect = sidebar.getBoundingClientRect();
        return { position: style.position, threshold: parseFloat(style.top),
                 top: rect.top, left: rect.left, width: rect.width };
      })()
    JS
    expect(initial["position"]).to eq("sticky")
    expect(initial["top"]).to be >= initial["threshold"]

    page.execute_script("window.scrollTo(0, 600)")
    try_until_success do
      current = page.evaluate_script(<<~JS)
        (() => {
          const rect = document.querySelector('.custom-right-sidebar').getBoundingClientRect();
          return { top: rect.top, left: rect.left, width: rect.width, scroll: window.scrollY };
        })()
      JS
      expect(current["scroll"]).to be > 0
      expect(current["top"]).to be_within(1).of(initial["threshold"])
      expect(current["left"]).to be_within(1).of(initial["left"])
      expect(current["width"]).to be_within(1).of(initial["width"])
    end
  end

  it "allows long modules to scroll inside the right column" do
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome")
    page.execute_script(<<~JS)
      const sidebar = document.querySelector('.custom-right-sidebar');
      const module = document.createElement('div');
      module.style.minHeight = '1200px';
      sidebar.append(module);
      sidebar.scrollTop = 300;
    JS

    metrics = page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector('.custom-right-sidebar');
        const rect = sidebar.getBoundingClientRect();
        return { scroll: sidebar.scrollTop, overflow: getComputedStyle(sidebar).overflowY,
                 bottom: rect.bottom, viewport: window.innerHeight };
      })()
    JS
    expect(metrics["overflow"]).to eq("auto")
    expect(metrics["scroll"]).to be > 0
    expect(metrics["bottom"]).to be <= metrics["viewport"]
  end

  it "keeps the right column hidden on small screens" do
    page.current_window.resize_to(390, 844)
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome", visible: :all)
    expect(page).to have_no_css(".custom-right-sidebar", visible: true)
  end
end
