class StreamBroadcaster
  attr_reader :chunk, :client, :message_id, :thread_id

  def initialize(client:, message_id:, thread_id:)
    @client = client
    @message_id = message_id
    @thread_id = thread_id
    @content = ""
  end

  def call(chunk)
    @chunk = chunk
    if chunk["object"] == "thread.message.delta"
      content << chunk.dig("delta", "content", 0, "text", "value")
      broadcast_response
    elsif chunk.dig("status") == "requires_action"
      ToolCallHandler.call(self)
    end
  end

  private

  attr_accessor :content

  def broadcast_response
    assistant_message = Message.new(
      id: "assistant_#{message_id}",
      content: content,
      role: "assistant"
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      :messages,
      target: assistant_message,
      partial: "messages/message",
      locals: {message: assistant_message}
    )
  end
end
