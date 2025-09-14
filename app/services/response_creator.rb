class ResponseCreator
  def create_response(message:)
    input = [{role: "user", content: message.content }]
    stream = client.responses.stream(
      input: input,
      prompt: {
        id: ENV["OPENAI_PROMPT_ID"],
      },
    )

    content = ""
    stream.each do |event|
      puts ("--- events from first stream ---")
      puts event
      case event
      when OpenAI::Streaming::ResponseTextDeltaEvent
        content << event.delta
        assistant_message = Message.new(id: message.id, content:, role: "assistant")
        broadcast_response(assistant_message)
      end
    end
    response = stream.get_final_response
    input += response.output

    response
    .output
    .each do |output|
      case output
      when OpenAI::Models::Responses::ResponseFunctionToolCall
        tool_output = tools.public_send(output.name, output.arguments)
        input.push({
          type: :"function_call_output",
          call_id: output.call_id,
          output: tool_output
        })
      end
    end

    stream_with_tool_output = client.responses.stream(
      input: input,
      prompt: {
        id: ENV["OPENAI_PROMPT_ID"],
      },
    )

    content = ""
    stream_with_tool_output.each do |event|
      puts ("--- events from second stream ---")
      puts event
      case event
      when OpenAI::Streaming::ResponseTextDeltaEvent
        content << event.delta
        assistant_message = Message.new(id: message.id, content:, role: "assistant")
        broadcast_response(assistant_message)
      end
    end
  end

  private

  def client
    @client ||= OpenAI::Client.new
  end

  def additional_instructions
    "The current date and time is #{DateTime.current}."
  end

  def broadcast_response(assistant_message)
    Turbo::StreamsChannel.broadcast_render_to(
      :messages,
      partial: "messages/assistant_message",
      locals: { message: assistant_message }
    )
  end

  def tools
    @tools ||= Tools.new
  end
end

