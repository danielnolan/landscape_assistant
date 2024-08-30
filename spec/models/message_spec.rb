require "rails_helper"

RSpec.describe Message do
  describe "#create" do
    it "creates a new message" do
      messages = double
      allow(messages).to receive(:create).and_return({"id" => "abc123"})
      client = instance_double(OpenAI::Client, messages: messages)
      allow(OpenAI::Client).to receive(:new).and_return(client)

      message = Message.new(message_params).create

      expect(messages).to have_received(:create)
      expect(message.id).to eq("abc123")
    end
  end

  def message_params
    {role: "user", content: "Hello", thread_id: "thread_123"}
  end
end
