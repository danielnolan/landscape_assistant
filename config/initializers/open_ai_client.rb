class OpenAIClient
  include Singleton

  def client
    @client ||= OpenAI::Client.new
  end
end
