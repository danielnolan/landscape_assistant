module Assistants
  class Run
    include Assistants

    def initialize(sse, thread_id)
      @sse = sse
      @thread_id = thread_id
    end

    def stream
      client.runs.create(
        thread_id: thread_id,
        parameters: {
          assistant_id: assistant_id,
          additional_instructions: additonal_instructions,
          stream: stream_response
        }
      )
    end

    private

    attr_reader :sse, :thread_id

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
end
