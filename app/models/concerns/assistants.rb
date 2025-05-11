module Assistants

  private

  def client
    @client ||= OpenAI::Client.new
  end

  def assistant_id
    @assistant_id ||= ENV["OPEN_AI_ASSISTANT_ID"]
  end
end
