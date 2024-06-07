class MessagesController < ApplicationController
  include ActionController::Live
  skip_before_action :verify_authenticity_token

  def index
    @thread_id = thread_id
    if thread_id.nil?
      response = client.threads.create
      @thread_id = response["id"]
    else
      messages = client.messages.list(thread_id: thread_id)
      @messages = messages["data"].map do |message|
        {text: message["content"][0]["text"]["value"], role: message["role"]}
      end.to_json
    end
    @threads = ChatThread.order(created_at: :desc)
  end

  def create
    # TODO: Handle Image Uploads
    response.headers["Content-Type"] = "text/event-stream"
    create_message
    client.runs.create(thread_id: thread_id,
      parameters: {
        assistant_id: assistant_id,
        stream: stream_response,
        additional_instructions: additonal_instructions
      })
  ensure
    sse.close
  end

  private

  def sse
    @sse ||= SSE.new(response.stream, retry: 300, event: "event-name")
  end

  def create_message
    message = params[:messages].first
    client.messages.create(
      thread_id: thread_id,
      parameters: {role: message[:role], content: message[:text]}
    )
  end

  def additonal_instructions
    "The current date and time is #{DateTime.current}. \n The current thread_id is #{thread_id}."
  end

  def stream_response
    proc do |chunk, _bytesize|
      if chunk["object"] == "thread.message.delta"
        sse.write({text: chunk.dig("delta", "content", 0, "text", "value")})
      elsif chunk.dig("status") == "requires_action"
        handle_tool_calls(chunk)
      end
    end
  end

  def handle_tool_calls(chunk)
    tools_to_call = chunk.dig("required_action", "submit_tool_outputs", "tool_calls")

    my_tool_outputs = tools_to_call.map { |tool|
      function_name = tool.dig("function", "name")
      arguments = tool.dig("function", "arguments")

      tool_functions = AssistantFunctions.new
      tool_output = tool_functions.public_send(function_name, arguments)

      {tool_call_id: tool["id"], output: tool_output}
    }

    client.runs.submit_tool_outputs(
      thread_id: thread_id,
      run_id: chunk.dig("id"),
      parameters: {
        tool_outputs: my_tool_outputs,
        stream: stream_response
      }
    )
  end

  def thread_id
    params[:thread_id]
  end

  def client
    @client ||= OpenAI::Client.new
  end

  def assistant_id
    Rails.application.credentials.open_ai.dig("assistant_id")
  end

  def message_params
    params.permit(:messages, :thread_id)
  end
end
