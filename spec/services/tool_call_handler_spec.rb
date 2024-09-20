require "rails_helper"

RSpec.describe ToolCallHandler do
  describe "#call" do
    it "calls the proper tool and submits it's output" do
      stream_broadcaster = double(
        "StreamBroadcaster",
        chunk: {
          "required_action" => {
            "submit_tool_outputs" => {
              "tool_calls" => [
                {
                  "id" => "1",
                  "function" => {
                    "name" => "get_weather",
                    "arguments" => {}
                  }
                }
              ]
            }
          }
        },
        client: double("Client"),
        thread_id: "456"
      )
      tools = double("Tools")
      handler = ToolCallHandler.new(stream_broadcaster)
      allow(Tools).to receive(:new).and_return(tools)
      allow(stream_broadcaster.client).to receive_message_chain(:runs, :submit_tool_outputs)
      expect(tools).to receive(:public_send).with("get_weather", {}).and_return("output")

      handler.call

      expect(stream_broadcaster.client.runs).to have_received(:submit_tool_outputs).with(
        thread_id: "456",
        run_id: nil,
        parameters: {
          tool_outputs: [{tool_call_id: "1", output: "output"}],
          stream: stream_broadcaster
        }
      )
    end
  end
end

