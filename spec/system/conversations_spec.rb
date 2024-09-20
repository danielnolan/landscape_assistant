require "rails_helper"

RSpec.describe "Conversations" do
  include ActiveJob::TestHelper

  it "creates a new thread, and shows the assistant name" do
    cassettes = [
      {name: "get_assistant"},
      {name: "create_thread"}
    ]
    VCR.use_cassettes cassettes do
      visit root_url

      expect(page).to have_text("Hummingbird Holler's Horticulture Hero")
    end
  end

  it "allows me to send a message to the assistant" do
    cassettes = [
      {name: "get_assistant"},
      {name: "create_thread"},
      {name: "create_message"}
    ]
    VCR.use_cassettes cassettes do
      visit root_url

      fill_in "How can I help?", with: "Hey what's up"
      click_button "Send"
      perform_enqueued_jobs

      expect(page).to have_text("How can I help you today?")
    end
  end
end
