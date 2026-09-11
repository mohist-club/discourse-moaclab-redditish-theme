# frozen_string_literal: true

RSpec.describe "Content surfaces", system: true do
  let!(:theme) { upload_theme }
  fab!(:user)
  fab!(:post)

  before { page.current_window.resize_to(1440, 900) }

  it "removes page frames in search, profiles, the directory and about" do
    SiteSetting.enable_user_directory = true
    pages = {
      "/search?q=keyboard" => ".search-container",
      "/u/#{user.username}/summary" => ".user-main",
      "/u?order=likes_received" => ".users-page #main-outlet",
      "/about" => ".body-page",
    }

    pages.each do |path, selector|
      visit(path)
      expect(page).to have_css(selector)
      find(selector).hover
      appearance = page.evaluate_script(<<~JS)
        (() => {
          const style = getComputedStyle(document.querySelector(#{selector.to_json}));
          return { borders: [style.borderTopWidth, style.borderRightWidth,
                             style.borderBottomWidth, style.borderLeftWidth],
                   shadow: style.boxShadow };
        })()
      JS
      expect(appearance["borders"]).to eq(%w[0px 0px 0px 0px])
      expect(appearance["shadow"]).to eq("none")
    end
  end

  it "caps suggested cards outside discovery routes without limiting the post" do
    3.times { Fabricate(:post) }
    visit("/t/#{post.topic.slug}/#{post.topic_id}")
    expect(page).to have_css(".cooked")
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    expect(page).to have_css(".topic-list .moaclab-feed-item")

    [1440, 390].each do |width|
      page.current_window.resize_to(width, 900)
      try_until_success do
        layout = page.evaluate_script(<<~JS)
          (() => {
            const card = document.querySelector('.topic-list .moaclab-feed-item');
            const list = card.closest('.topic-list');
            return { card: card.getBoundingClientRect().width,
                     list: list.getBoundingClientRect().width,
                     fits: document.documentElement.scrollWidth <= innerWidth };
          })()
        JS
        expect(layout["card"]).to be > 0
        expect(layout["card"]).to be <= 700
        expect(layout["list"]).to be <= 700
        expect(layout["fits"]).to eq(true)
      end
    end
  end
end
