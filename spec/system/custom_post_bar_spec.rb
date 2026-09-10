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
