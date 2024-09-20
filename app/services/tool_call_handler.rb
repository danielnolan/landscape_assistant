class ToolCallHandler
  def self.call(...) = new(...).call

  def initialize(stream_broadcaster)
    @stream_broadcaster = stream_broadcaster
    @tools = Tools.new
  end

  def call
    handle_tool_calls
  end

  private

  attr_reader :stream_broadcaster, :tools

  def tools_to_call
    stream_broadcaster.chunk.dig(
      "required_action", "submit_tool_outputs", "tool_calls"
    )
  end

  def tool_outputs
    tools_to_call.map do |tool|
      function_name = tool.dig("function", "name")
      arguments = tool.dig("function", "arguments")
      Async do
        tool_output = tools.public_send(function_name, arguments)
        {tool_call_id: tool["id"], output: tool_output}
      end
    end.map(&:wait)
  end

  def handle_tool_calls
    Rails.logger.debug("handle tools called")
    Rails.logger.debug(tool_outputs)

    stream_broadcaster.client.runs.submit_tool_outputs(
      thread_id: stream_broadcaster.thread_id,
      run_id: stream_broadcaster.chunk.dig("id"),
      parameters: {
        tool_outputs: tool_outputs,
        stream: stream_broadcaster
      }
    )
  ensure
    Faraday.default_connection.close
  end
end
