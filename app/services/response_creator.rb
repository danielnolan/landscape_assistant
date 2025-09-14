class ResponseCreator
  def create_response(message:)
    input = [{role: "user", content: message.content}]
    stream = client.responses.stream(
      input: input,
      prompt: {id: ENV["OPENAI_PROMPT_ID"]}
    )
    stream_and_broadcast(stream:, message:)

    response = stream.get_final_response
    input += response.output

    input_with_tool_calls = handle_tool_calls(input:, outputs: response.output)

    stream_with_tool_output = client.responses.stream(
      input: input_with_tool_calls,
      prompt: {id: ENV["OPENAI_PROMPT_ID"]}
    )
    stream_and_broadcast(stream: stream_with_tool_output, message:)
  end

  private

  def handle_tool_calls(input:, outputs:)
    outputs.each do |output|
      if output.is_a?(OpenAI::Models::Responses::ResponseFunctionToolCall)
        tool_output = tools.public_send(output.name, output.arguments)
        input << {
          type: :function_call_output,
          call_id: output.call_id,
          output: tool_output
        }
      end
    end
    input
  end

  def stream_and_broadcast(stream:, message:)
    content = ""
    stream.each do |event|
      puts("--- events from stream ---")
      puts event
      if event.is_a?(OpenAI::Streaming::ResponseTextDeltaEvent)
        content << event.delta
        assistant_message = Message.new(id: message.id, content:, role: "assistant")
        broadcast_response(assistant_message)
      end
    end
    content
  end

  def client
    @client ||= OpenAI::Client.new
  end

  def broadcast_response(assistant_message)
    Turbo::StreamsChannel.broadcast_render_to(
      :messages,
      partial: "messages/assistant_message",
      locals: {message: assistant_message}
    )
  end

  def tools
    @tools ||= Tools.new
  end
end
