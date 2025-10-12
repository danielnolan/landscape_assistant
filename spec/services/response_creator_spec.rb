require "rails_helper"

RSpec.describe ResponseCreator, type: :service do
  describe "#create_response" do
    context "when there are no tool calls" do
      it "creates a streaming response with the OpenAI client" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([])
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).with(
          input: message.content,
          conversation: message.conversation_id,
          prompt: { id: ENV["OPENAI_PROMPT_ID"] },
          tools: [
            Tools::GetLocalWeatherAndSoilMoisture,
            Tools::GetWeather,
            Tools::SaveConversation
          ]
        )
      end

      it "streams and broadcasts the response" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream)
        allow(text_delta_event).to receive(:is_a?)
          .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([])
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

        described_class.new.create_response(message: message)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_render_to).with(
          :messages,
          partial: "messages/assistant_message",
          locals: { message: an_instance_of(Message) }
        )
      end

      it "does not create a second stream when no tool calls are present" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([])
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).once
      end
    end

    context "when there are tool calls" do
      it "handles tool calls and creates a second stream" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_output = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-123",
          arguments: { location: "San Francisco" }
        )
        parsed_tool = double("ParsedTool")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_output ])
        allow(tool_call_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_output).to receive(:parsed).and_return(parsed_tool)
        allow(parsed_tool).to receive(:call).with(arguments: tool_call_output.arguments)
          .and_return("Weather data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).twice
      end

      it "logs the tool call information" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_output = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-123",
          arguments: { location: "San Francisco" }
        )
        parsed_tool = double("ParsedTool")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_output ])
        allow(tool_call_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_output).to receive(:parsed).and_return(parsed_tool)
        allow(parsed_tool).to receive(:call).with(arguments: tool_call_output.arguments)
          .and_return("Weather data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(Rails.logger).to have_received(:info).with(
          "Handling tool call: GetWeather with arguments: #{tool_call_output.arguments}"
        )
      end

      it "creates a second stream with tool call outputs" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_output = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-123",
          arguments: { location: "San Francisco" }
        )
        parsed_tool = double("ParsedTool")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_output ])
        allow(tool_call_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_output).to receive(:parsed).and_return(parsed_tool)
        allow(parsed_tool).to receive(:call).with(arguments: tool_call_output.arguments)
          .and_return("Weather data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).with(
          input: [
            {
              type: :function_call_output,
              call_id: "call-123",
              output: "Weather data"
            }
          ],
          conversation: message.conversation_id,
          prompt: { id: ENV["OPENAI_PROMPT_ID"] }
        )
      end

      it "executes the tool with the provided arguments" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_output = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-123",
          arguments: { location: "San Francisco" }
        )
        parsed_tool = double("ParsedTool")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_output ])
        allow(tool_call_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_output).to receive(:parsed).and_return(parsed_tool)
        allow(parsed_tool).to receive(:call).with(arguments: tool_call_output.arguments)
          .and_return("Weather data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(parsed_tool).to have_received(:call).with(arguments: tool_call_output.arguments)
      end
    end

    context "when there are multiple tool calls" do
      it "handles all tool calls" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_1 = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-1",
          arguments: { location: "San Francisco" }
        )
        tool_call_2 = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetLocalWeatherAndSoilMoisture",
          call_id: "call-2",
          arguments: { sensor_id: "sensor-123" }
        )
        parsed_tool_1 = double("ParsedTool1")
        parsed_tool_2 = double("ParsedTool2")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_1, tool_call_2 ])
        allow(tool_call_1).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_2).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_1).to receive(:parsed).and_return(parsed_tool_1)
        allow(tool_call_2).to receive(:parsed).and_return(parsed_tool_2)
        allow(parsed_tool_1).to receive(:call).and_return("Weather data")
        allow(parsed_tool_2).to receive(:call).and_return("Soil moisture data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(parsed_tool_1).to have_received(:call)
        expect(parsed_tool_2).to have_received(:call)
      end

      it "includes all tool outputs in the second stream" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        tool_call_1 = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-1",
          arguments: { location: "San Francisco" }
        )
        tool_call_2 = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetLocalWeatherAndSoilMoisture",
          call_id: "call-2",
          arguments: { sensor_id: "sensor-123" }
        )
        parsed_tool_1 = double("ParsedTool1")
        parsed_tool_2 = double("ParsedTool2")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ tool_call_1, tool_call_2 ])
        allow(tool_call_1).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_2).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_1).to receive(:parsed).and_return(parsed_tool_1)
        allow(tool_call_2).to receive(:parsed).and_return(parsed_tool_2)
        allow(parsed_tool_1).to receive(:call).and_return("Weather data")
        allow(parsed_tool_2).to receive(:call).and_return("Soil moisture data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).with(
          hash_including(
            input: array_including(
              hash_including(call_id: "call-1", output: "Weather data"),
              hash_including(call_id: "call-2", output: "Soil moisture data")
            )
          )
        )
      end
    end

    context "when output contains non-tool-call items" do
      it "filters out non-tool-call outputs" do
        message = Message.new(
          id: 1,
          content: "What's the weather like?",
          role: "user",
          conversation_id: "conv-123"
        )
        open_ai_client = instance_double(OpenAI::Client)
        responses_double = instance_double(OpenAI::Resources::Responses)
        stream = instance_double(OpenAI::Streaming::ResponseStream)
        final_response = instance_double(OpenAI::Models::Responses::Response)
        text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
        text_output = instance_double(OpenAI::Models::Responses::ResponseOutputText)
        tool_call_output = instance_double(
          OpenAI::Models::Responses::ResponseFunctionToolCall,
          name: "GetWeather",
          call_id: "call-123",
          arguments: { location: "San Francisco" }
        )
        parsed_tool = double("ParsedTool")
        second_stream = instance_double(OpenAI::Streaming::ResponseStream)
        second_response = instance_double(OpenAI::Models::Responses::Response, output: [])

        allow(OpenAIClient).to receive(:instance).and_return(
          instance_double(OpenAIClient, client: open_ai_client)
        )
        allow(open_ai_client).to receive(:responses).and_return(responses_double)
        allow(responses_double).to receive(:stream).and_return(stream, second_stream)
        allow(stream).to receive(:each).and_yield(text_delta_event)
        allow(stream).to receive(:get_final_response).and_return(final_response)
        allow(final_response).to receive(:output).and_return([ text_output, tool_call_output ])
        allow(text_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(false)
        allow(tool_call_output).to receive(:is_a?)
          .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
        allow(tool_call_output).to receive(:parsed).and_return(parsed_tool)
        allow(parsed_tool).to receive(:call).and_return("Weather data")
        allow(second_stream).to receive(:each).and_yield(text_delta_event)
        allow(second_stream).to receive(:get_final_response).and_return(second_response)
        allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)
        allow(Rails.logger).to receive(:info)

        described_class.new.create_response(message: message)

        expect(responses_double).to have_received(:stream).with(
          hash_including(
            input: [
              {
                type: :function_call_output,
                call_id: "call-123",
                output: "Weather data"
              }
            ]
          )
        )
      end
    end
  end

  describe "#handle_tool_calls" do
    it "returns tool call outputs in the correct format" do
      tool_call = instance_double(
        OpenAI::Models::Responses::ResponseFunctionToolCall,
        name: "GetWeather",
        call_id: "call-123",
        arguments: { location: "San Francisco" }
      )
      parsed_tool = double("ParsedTool")

      allow(tool_call).to receive(:is_a?)
        .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
      allow(tool_call).to receive(:parsed).and_return(parsed_tool)
      allow(parsed_tool).to receive(:call).with(arguments: tool_call.arguments)
        .and_return("Tool output")
      allow(Rails.logger).to receive(:info)

      result = described_class.new.send(:handle_tool_calls, outputs: [ tool_call ])

      expect(result).to eq([
        {
          type: :function_call_output,
          call_id: "call-123",
          output: "Tool output"
        }
      ])
    end

    it "filters out non-tool-call outputs" do
      non_tool_output = instance_double(OpenAI::Models::Responses::ResponseOutputText)
      tool_call = instance_double(
        OpenAI::Models::Responses::ResponseFunctionToolCall,
        name: "GetWeather",
        call_id: "call-123",
        arguments: { location: "San Francisco" }
      )
      parsed_tool = double("ParsedTool")

      allow(non_tool_output).to receive(:is_a?)
        .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(false)
      allow(tool_call).to receive(:is_a?)
        .with(OpenAI::Models::Responses::ResponseFunctionToolCall).and_return(true)
      allow(tool_call).to receive(:parsed).and_return(parsed_tool)
      allow(parsed_tool).to receive(:call).with(arguments: tool_call.arguments)
        .and_return("Tool output")
      allow(Rails.logger).to receive(:info)

      result = described_class.new.send(:handle_tool_calls, outputs: [ non_tool_output, tool_call ])

      expect(result.length).to eq(1)
      expect(result.first[:call_id]).to eq("call-123")
    end

    it "returns empty array when no tool calls are present" do
      result = described_class.new.send(:handle_tool_calls, outputs: [])

      expect(result).to eq([])
    end
  end

  describe "#stream_and_broadcast" do
    it "accumulates content from text delta events" do
      message = Message.new(
        id: 1,
        content: "What's the weather like?",
        role: "user",
        conversation_id: "conv-123"
      )
      stream = instance_double(OpenAI::Streaming::ResponseStream)
      text_delta_event_1 = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello ")
      text_delta_event_2 = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "world!")

      allow(text_delta_event_1).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(text_delta_event_2).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(stream).to receive(:each).and_yield(text_delta_event_1).and_yield(text_delta_event_2)
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

      result = described_class.new.send(:stream_and_broadcast, stream: stream, message: message)

      expect(result).to eq("Hello world!")
    end

    it "broadcasts each delta to Turbo Streams" do
      message = Message.new(
        id: 1,
        content: "What's the weather like?",
        role: "user",
        conversation_id: "conv-123"
      )
      stream = instance_double(OpenAI::Streaming::ResponseStream)
      text_delta_event_1 = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello ")
      text_delta_event_2 = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "world!")

      allow(text_delta_event_1).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(text_delta_event_2).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(stream).to receive(:each).and_yield(text_delta_event_1).and_yield(text_delta_event_2)
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

      described_class.new.send(:stream_and_broadcast, stream: stream, message: message)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_render_to).with(
        :messages,
        partial: "messages/assistant_message",
        locals: { message: an_instance_of(Message) }
      ).twice
    end

    it "only processes ResponseTextDeltaEvent events" do
      message = Message.new(
        id: 1,
        content: "What's the weather like?",
        role: "user",
        conversation_id: "conv-123"
      )
      stream = instance_double(OpenAI::Streaming::ResponseStream)
      non_text_event = instance_double(OpenAI::Models::Responses::ResponseCompletedEvent)
      text_delta_event_1 = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")

      allow(non_text_event).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(false)
      allow(text_delta_event_1).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(stream).to receive(:each).and_yield(non_text_event).and_yield(text_delta_event_1)
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

      described_class.new.send(:stream_and_broadcast, stream: stream, message: message)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_render_to).once
    end

    it "broadcasts messages with assistant role" do
      message = Message.new(
        id: 1,
        content: "What's the weather like?",
        role: "user",
        conversation_id: "conv-123"
      )
      stream = instance_double(OpenAI::Streaming::ResponseStream)
      text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
      broadcasted_message = nil

      allow(text_delta_event).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(stream).to receive(:each).and_yield(text_delta_event)
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |_, options|
        broadcasted_message = options[:locals][:message]
      end

      described_class.new.send(:stream_and_broadcast, stream: stream, message: message)

      expect(broadcasted_message.role).to eq("assistant")
    end

    it "broadcasts messages with the same ID as the original message" do
      message = Message.new(
        id: 1,
        content: "What's the weather like?",
        role: "user",
        conversation_id: "conv-123"
      )
      stream = instance_double(OpenAI::Streaming::ResponseStream)
      text_delta_event = instance_double(OpenAI::Streaming::ResponseTextDeltaEvent, delta: "Hello")
      broadcasted_message = nil

      allow(text_delta_event).to receive(:is_a?)
        .with(OpenAI::Streaming::ResponseTextDeltaEvent).and_return(true)
      allow(stream).to receive(:each).and_yield(text_delta_event)
      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to) do |_, options|
        broadcasted_message = options[:locals][:message]
      end

      described_class.new.send(:stream_and_broadcast, stream: stream, message: message)

      expect(broadcasted_message.id).to eq(message.id)
    end
  end

  describe "#open_ai_client" do
    it "returns the client from OpenAIClient singleton" do
      open_ai_client = instance_double(OpenAI::Client)

      allow(OpenAIClient).to receive(:instance).and_return(
        instance_double(OpenAIClient, client: open_ai_client)
      )

      client = described_class.new.send(:open_ai_client)

      expect(client).to eq(open_ai_client)
    end
  end

  describe "#broadcast_response" do
    it "broadcasts to the :messages channel" do
      assistant_message = Message.new(
        id: 1,
        content: "Hello!",
        role: "assistant"
      )

      allow(Turbo::StreamsChannel).to receive(:broadcast_render_to)

      described_class.new.send(:broadcast_response, assistant_message)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_render_to).with(
        :messages,
        partial: "messages/assistant_message",
        locals: { message: assistant_message }
      )
    end
  end
end
