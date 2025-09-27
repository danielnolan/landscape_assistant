class ResponseCreator
  def create_response(message:)
    stream = open_ai_client.responses.stream(
      input: message.content,
      conversation: message.conversation_id,
      prompt: {id: ENV["OPENAI_PROMPT_ID"]},
      tools: [
        Tools::GetLocalWeatherAndSoilMoisture,
        Tools::GetWeather,
        Tools::SaveConversation
      ]
    )
    stream_and_broadcast(stream:, message:)

    response = stream.get_final_response
    tool_call_outputs = handle_tool_calls(outputs: response.output)

    unless tool_call_outputs.empty?
      stream_with_tool_input = open_ai_client.responses.stream(
        input: tool_call_outputs,
        conversation: message.conversation_id,
        prompt: {id: ENV["OPENAI_PROMPT_ID"]}
      )
      stream_and_broadcast(stream: stream_with_tool_input, message:)
    end
  end

  private

  def handle_tool_calls(outputs:)
    outputs.filter_map do |output|
      if output.is_a?(OpenAI::Models::Responses::ResponseFunctionToolCall)
        Rails.logger.info("Handling tool call: #{output.name} with arguments: #{output.arguments}")
        tool_output = output.parsed.call(arguments: output.arguments)
        {
          type: :function_call_output,
          call_id: output.call_id,
          output: tool_output
        }
      end
    end
  end

  def stream_and_broadcast(stream:, message:)
    content = ""
    stream.each do |event|
      if event.is_a?(OpenAI::Streaming::ResponseTextDeltaEvent)
        content << event.delta
        assistant_message = Message.new(id: message.id, content:, role: "assistant")
        broadcast_response(assistant_message)
      end
    end
    content
  end

  def open_ai_client
    OpenAIClient.instance.client
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
