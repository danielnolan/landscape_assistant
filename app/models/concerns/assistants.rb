module Assistants

  private

  def client
    @client ||= OpenAI::Client.new
  end

  def assistant_id
    @assistant_id ||= Rails.application.credentials.open_ai.dig("assistant_id")
  end
end
