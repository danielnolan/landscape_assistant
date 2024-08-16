class Run
  include Assistants

  def initialize(message_id, thread_id)
    @message_id = message_id
    @thread_id = thread_id
    @content = ""
  end

  def create
    client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: assistant_id,
        additional_instructions: additional_instructions,
        stream: stream_response
      }
    )
  end

  private

  attr_accessor :content
  attr_reader :thread_id, :message_id

  def additional_instructions
    "The current date and time is #{DateTime.current}. \n The current thread_id is #{thread_id}."
  end

  def stream_response
    proc do |chunk, _bytesize|
      if chunk["object"] == "thread.message.delta"
        content << chunk.dig("delta", "content", 0, "text", "value")
        message = Message.new(content: content, role: "system")
        broadcast_response(message)
      elsif chunk.dig("status") == "requires_action"
        handle_tool_calls(chunk)
      end
    end
  end

  def broadcast_response(message)
    Turbo::StreamsChannel.broadcast_append_to(
      :messages,
      target: "messages",
      partial: "messages/message",
      locals: {message: message}
    )
  end

  def handle_tool_calls(chunk)
    Rails.logger.debug("handle tools called")
    tools_to_call = chunk.dig("required_action", "submit_tool_outputs", "tool_calls")
    my_tool_outputs = tools_to_call.map do |tool|
      function_name = tool.dig("function", "name")
      arguments = tool.dig("function", "arguments")
      Async do
        tool_output = tools.public_send(function_name, arguments)
        {tool_call_id: tool["id"], output: tool_output}
      end
    end.map(&:wait)

    Rails.logger.debug(my_tool_outputs)

    client.runs.submit_tool_outputs(
      thread_id: thread_id,
      run_id: chunk.dig("id"),
      parameters: {
        tool_outputs: my_tool_outputs,
        stream: stream_response
      }
    )
  ensure
    Faraday.default_connection.close
  end

  def tools
    @tools ||= Tools.new
  end
end
