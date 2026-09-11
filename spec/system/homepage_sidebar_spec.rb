# frozen_string_literal: true

RSpec.describe "Homepage sidebar", system: true do
  let!(:theme) { upload_theme }

  before do
    SiteSetting.top_menu = "latest|hot|top"
    12.times { Fabricate(:post) }
    page.current_window.resize_to(1440, 700)
  end

  it "keeps only the recent topics and leaderboard group sticky" do
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome")

    initial = page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector('.moaclab-home-sidebar-sticky');
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
          const rect = document.querySelector('.moaclab-home-sidebar-sticky').getBoundingClientRect();
          const welcome = document.querySelector('.custom-right-sidebar_welcome');
          return { top: rect.top, left: rect.left, width: rect.width, scroll: window.scrollY,
                   welcomeBottom: welcome.getBoundingClientRect().bottom };
        })()
      JS
      expect(current["scroll"]).to be > 0
      expect(current["top"]).to be_within(1).of(initial["threshold"])
      expect(current["left"]).to be_within(1).of(initial["left"])
      expect(current["width"]).to be_within(1).of(initial["width"])
      expect(current["welcomeBottom"]).to be < 0
    end
  end

  it "does not create an internal scrollbar even in a tall desktop window" do
    page.current_window.resize_to(1440, 1000)
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome")
    page.execute_script(<<~JS)
      const sidebar = document.querySelector('.custom-right-sidebar');
      const module = document.createElement('div');
      module.style.minHeight = '1200px';
      sidebar.querySelector('.moaclab-home-sidebar-sticky').append(module);
      sidebar.scrollTop = 300;
    JS

    metrics = page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector('.custom-right-sidebar');
        const group = sidebar.querySelector('.moaclab-home-sidebar-sticky');
        return { scroll: sidebar.scrollTop, overflow: getComputedStyle(sidebar).overflowY,
                 position: getComputedStyle(sidebar).position,
                 groupOverflow: getComputedStyle(group).overflowY,
                 maxHeight: getComputedStyle(sidebar).maxHeight };
      })()
    JS
    expect(metrics["position"]).to eq("static")
    expect(metrics["overflow"]).to eq("visible")
    expect(metrics["groupOverflow"]).to eq("visible")
    expect(metrics["maxHeight"]).to eq("none")
    expect(metrics["scroll"]).to eq(0)
  end

  it "keeps the right column hidden on small screens" do
    page.current_window.resize_to(390, 844)
    visit("/latest")
    expect(page).to have_css(".custom-right-sidebar_welcome", visible: :all)
    expect(page).to have_no_css(".custom-right-sidebar", visible: true)
  end
end
