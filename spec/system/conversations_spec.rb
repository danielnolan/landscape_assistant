require "rails_helper"

RSpec.describe "Conversations" do
  include ActiveJob::TestHelper

  it "creates a new thread, and shows the assistant name" do
    VCR.insert_cassette "get_assistant"
    VCR.use_cassette "create_thread" do

      visit root_url

      expect(page).to have_text("Hummingbird Holler's Horticulture Hero")
    end
    VCR.eject_cassette
  end

  it "allows me to send a message to the assistant" do
    VCR.insert_cassette "get_assistant"
    VCR.insert_cassette "create_thread"
    VCR.use_cassette "create_message" do
      visit root_url

      fill_in "How can I help?", with: "Hey what's up"
      click_button "Send"
      perform_enqueued_jobs

      expect(page).to have_text("How can I help you today?")
    end
    VCR.eject_cassette
  end
end
