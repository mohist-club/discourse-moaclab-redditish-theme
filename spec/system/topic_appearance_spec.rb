# frozen_string_literal: true

RSpec.describe "Topic appearance", system: true do
  let!(:theme) { upload_theme }
  fab!(:post) do
    raw = "A topic with a quoted note.\n\n> Keep this quote readable."
    Fabricate(:post, raw: raw)
  end

  it "removes the surrounding frame without removing quote styling" do
    page.current_window.resize_to(1440, 900)
    visit("/t/#{post.topic.slug}/#{post.topic_id}")
    expect(page).to have_css(".posts-wrapper .cooked blockquote")

    appearance = page.evaluate_script(<<~JS)
      (() => {
        const frame = getComputedStyle(document.querySelector('.posts-wrapper'));
        const title = getComputedStyle(document.querySelector('#topic-title'));
        const quote = getComputedStyle(document.querySelector('.cooked blockquote'));
        return { border: frame.borderLeftWidth, shadow: frame.boxShadow,
                 title: title.backgroundColor, quoteBorder: quote.borderLeftWidth };
      })()
    JS
    expect(appearance["border"]).to eq("0px")
    expect(appearance["shadow"]).to eq("none")
    expect(appearance["title"]).to eq("rgba(0, 0, 0, 0)")
    expect(appearance["quoteBorder"].to_f).to be > 0

    page.current_window.resize_to(390, 844)
    fits = page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
    expect(fits).to eq(true)
  end
end
