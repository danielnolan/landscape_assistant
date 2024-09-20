require "rails_helper"

RSpec.describe Run do
  describe "#create" do
    it "creates a run with the correct parameters" do
      message_id = "123"
      thread_id = "456"
      assistant_id = Rails.application.credentials.open_ai.dig("assistant_id")
      client = double("Client")
      runs = double("Runs")
      stream_broadcaster = double("StreamBroadcaster")
      date_time = DateTime.current
      additional_instructions = <<~INSTRUCTIONS
        The current date and time is #{date_time}.
        The current thread_id is #{thread_id}.
      INSTRUCTIONS
      allow(DateTime).to receive(:current).and_return(date_time)
      allow(client).to receive(:runs).and_return(runs)
      allow(runs).to receive(:create)
      allow(OpenAI::Client).to receive(:new).and_return(client)
      allow(StreamBroadcaster).to receive(:new).and_return(stream_broadcaster)

      run = Run.new(message_id, thread_id)

      run.create

      expect(runs).to have_received(:create).with(
        thread_id: thread_id,
        parameters: {
          assistant_id: assistant_id,
          additional_instructions:,
          stream: stream_broadcaster
        }
      )
    end
  end
end

