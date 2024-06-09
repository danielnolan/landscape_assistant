require "rails_helper"

RSpec.describe Assistants::Message, type: :model do
  describe "#create" do
    it "creates a new message" do
      body = {role: "user", content: "Hello"}.to_json
      message = Assistants::Message.new(message_params)

      stub_create_success(body)

      expect(message.create).to eq("msg_123")
    end

    context "when files are present" do
      it "creates a new message with content from files" do
        body = {
          role: "user",
          content: [
            {type: "text", text: "Hello"},
            {type: "image_file", image_file: {file_id: "file_123"}}
          ]
        }.to_json
        message = Assistants::Message.new(message_with_image_params)
        stub_upload_file
        stub_create_success(body)

        expect(message.create).to eq("msg_123")
      end
    end
  end

  def file
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/code_ninja.png"))
  end

  def message_params
    {
      "messages" => [{"role" => "user", "text" => "Hello"}],
      "thread_id" => "thread_123"
    }.with_indifferent_access
  end

  def message_with_image_params
    {
      "files" => file,
      "message1" => '{"role": "user", "text": "Hello"}',
      "thread_id" => "thread_123"
    }.with_indifferent_access
  end

  def stub_create_success(body)
    stub_request(:post, "https://api.openai.com/v1/threads/thread_123/messages")
      .with(body: body)
      .to_return_json(status: 200, body: {id: "msg_123"}, headers: {})
  end

  def stub_upload_file
    stub_request(:post, "https://api.openai.com/v1/files")
      .to_return_json(status: 200, body: {id: "file_123"}, headers: {})
  end
end
