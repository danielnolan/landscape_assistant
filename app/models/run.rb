class Run
  include Assistants

  def initialize(message_id, thread_id)
    @message_id = message_id
    @thread_id = thread_id
  end

  def create
    client.runs.create(
      thread_id: thread_id,
      parameters: {
        assistant_id: assistant_id,
        additional_instructions: additional_instructions,
        stream: StreamBroadcaster.new(client:, message_id:, thread_id:)
      }
    )
  end

  private

  attr_reader :thread_id, :message_id

  def additional_instructions
    <<~INSTRUCTIONS
      The current date and time is #{DateTime.current}.
      The current thread_id is #{thread_id}.
    INSTRUCTIONS
  end
end
