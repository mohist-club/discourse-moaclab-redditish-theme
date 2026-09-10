# frozen_string_literal: true

RSpec.describe "Category sidebar", system: true do
  let!(:theme) { upload_theme }
  fab!(:category) { Fabricate(:category, name: "Keyboards") }
  fab!(:upload)
  fab!(:child) do
    Fabricate(:category, parent_category: category, name: "Studio", uploaded_logo: upload)
  end

  before { page.current_window.resize_to(1440, 700) }

  it "uses maintained logos and falls back to native category icons" do
    fallback = Fabricate(:category, parent_category: category, name: "Other", icon: "keyboard")
    visit("/c/#{category.slug}/#{category.id}")

    expect(page).to have_css(".moaclab-subcategory-logo img")
    logo_link = find(".moaclab-subcategory-with-logo", text: child.name)
    expect(logo_link[:href]).to include("/#{child.id}")
    expect(page).to have_css(".custom-right-sidebar_subcategories", text: fallback.name)

    logo_link.click
    expect(page).to have_css(".moaclab-category-hero__name", text: child.name)
  end

  it "supports dark-only category logos" do
    child.update!(uploaded_logo: nil, uploaded_logo_dark: upload)
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_css(".moaclab-subcategory-logo img")
  end

  it "sticks from its original position even on short desktop windows" do
    8.times { Fabricate(:post, topic: Fabricate(:topic, category: category)) }
    visit("/c/#{category.slug}/#{category.id}")
    expect(page).to have_css(".custom-right-sidebar_subcategories")

    before_scroll = page.evaluate_script(<<~JS)
      const sidebar = document.querySelector('.custom-right-sidebar');
      ({ top: sidebar.getBoundingClientRect().top,
         threshold: parseFloat(getComputedStyle(sidebar).top),
         position: getComputedStyle(sidebar).position });
    JS
    expect(before_scroll["position"]).to eq("sticky")
    expect(before_scroll["top"]).to be > before_scroll["threshold"]

    page.execute_script("window.scrollTo(0, 700)")
    try_until_success do
      current = page.evaluate_script(<<~JS)
        document.querySelector('.custom-right-sidebar').getBoundingClientRect().top
      JS
      expect(current).to be_within(1).of(before_scroll["threshold"])
    end
  end
end
