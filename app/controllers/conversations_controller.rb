class ConversationsController < ApplicationController
  def index
    @conversation = client.conversations.create
    @message = Message.new(conversation_id: @conversation.id, role: "user")
  end

  private

  def client
    @client ||= OpenAI::Client.new
  end
end
