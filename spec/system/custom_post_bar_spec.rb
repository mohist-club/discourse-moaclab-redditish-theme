# frozen_string_literal: true

RSpec.describe "Creating a topic from the custom post bar", system: true do
  let!(:theme) { upload_theme }
  let(:composer) { PageObjects::Components::Composer.new }

  # without refreshing auto groups the user isn't in trust_level_0, so
  # can_create_topic? is false and the post bar renders nothing
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }

  before do
    SiteSetting.top_menu = "latest|hot|categories"
    sign_in(user)
  end

  it "opens the composer when the fake input is clicked" do
    visit("/latest")

    find(".custom-post-bar-contents input").click

    expect(composer).to be_opened
  end

  it "aligns the post bar and navigation with the 700px feed" do
    Fabricate(:post)
    page.current_window.resize_to(1600, 1000)
    visit("/latest")
    expect(page).to have_css(".moaclab-feed-item")

    [1600, 1024, 390].each do |width|
      page.current_window.resize_to(width, 1000)
      try_until_success do
        layout = page.evaluate_script(<<~JS)
          (() => {
            const rect = selector => document.querySelector(selector).getBoundingClientRect();
            const card = rect('.moaclab-feed-item');
            const bar = rect('.custom-post-bar-contents');
            const nav = rect('#navigation-bar');
            const pill = rect('#navigation-bar > li:first-child > :is(a, button)');
            return { cardLeft: card.left, cardWidth: card.width, barLeft: bar.left,
                     barWidth: bar.width, navLeft: nav.left, pillLeft: pill.left,
                     fits: document.documentElement.scrollWidth <= window.innerWidth };
          })()
        JS
        expect(layout["navLeft"]).to be_within(1).of(layout["cardLeft"])
        expect(layout["pillLeft"]).to be_within(1).of(layout["cardLeft"])
        if width > 767
          expect(layout["barLeft"]).to be_within(1).of(layout["cardLeft"])
          expect(layout["barWidth"]).to be_within(1).of(layout["cardWidth"])
        else
          expect(page).to have_no_css(".custom-post-bar-contents", visible: true)
        end
        expect(layout["cardWidth"]).to be <= 700
        expect(layout["cardWidth"]).to be_within(1).of(700) if width == 1600
        expect(layout["fits"]).to eq(true)
      end
    end
  end

  it "only shows the post bar on the configured home feed" do
    category = Fabricate(:category)
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_no_css(".custom-post-bar")
    expect(page).to have_css(".moaclab-category-create")

    visit("/hot")
    expect(page).to have_no_css(".custom-post-bar")

    visit("/latest")
    expect(page).to have_css(".custom-post-bar-contents")
  end
end
