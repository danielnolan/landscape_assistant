require "rails_helper"

RSpec.describe StreamBroadcaster do
  describe "#call" do
    it "broadcasts message when chunk object is thread.message.delta" do
      message = double("Message")
      client = double("client")
      message_id = "123"
      thread_id = "456"
      chunk = {
        "object" => "thread.message.delta",
        "delta" => {
          "content" => [
            {"text" => {"value" => "Hello"}}
          ]
        }
      }
      broadcaster = StreamBroadcaster.new(
        client: client, message_id: message_id, thread_id: thread_id
      )
      allow(Message).to receive(:new).and_return(message)
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

      broadcaster.call(chunk)

      expect(Message).to have_received(:new).with(
        id: "assistant_#{message_id}",
        content: "Hello",
        role: "assistant"
      )
      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        :messages,
        target: message,
        partial: "messages/message",
        locals: {message: message}
      )
    end

    it "calls ToolCallHandler when chunk status is requires_action" do
      client = double("client")
      message_id = "123"
      thread_id = "456"
      chunk = {"status" => "requires_action"}
      broadcaster = StreamBroadcaster.new(
        client: client, message_id: message_id, thread_id: thread_id
      )
      allow(ToolCallHandler).to receive(:call)

      broadcaster.call(chunk)

      expect(ToolCallHandler).to have_received(:call).with(broadcaster)
    end
  end
end
