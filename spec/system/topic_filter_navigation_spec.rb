# frozen_string_literal: true

RSpec.describe "Topic filter navigation", system: true do
  let!(:theme) { upload_theme }
  fab!(:tag) { Fabricate(:tag, name: "keyboards") }
  fab!(:topic) { Fabricate(:topic, tags: [tag]) }

  before do
    SiteSetting.tagging_enabled = true
    page.current_window.resize_to(1440, 1000)
  end

  it "stays unframed on hover on homepage and tag feeds" do
    ["/latest", "/tag/#{tag.slug}/#{tag.id}"].each do |url|
      visit(url)
      find("#navigation-bar a", match: :first).hover
      border = page.evaluate_script(<<~JS)
        (() => {
          const style = getComputedStyle(document.querySelector('#navigation-bar'));
          return [style.borderTopWidth, style.borderRightWidth,
                  style.borderBottomWidth, style.borderLeftWidth];
        })()
      JS
      expect(border).to eq(%w[0px 0px 0px 0px])
    end
  end

  it "keeps native ranking navigation and period filtering" do
    visit("/tag/#{tag.slug}/#{tag.id}")
    find("#navigation-bar .nav-item_top a").click
    expect(page).to have_css("#navigation-bar .nav-item_top a[aria-current='page']")
    expect(page).to have_css("#navigation-bar a[aria-current='page']", count: 1)
    expect(page).to have_css(".period-chooser")
  end
end
