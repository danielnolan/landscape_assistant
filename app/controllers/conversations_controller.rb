class ConversationsController < ApplicationController
  def index
    conversation = client.conversations.create
    client.conversations.items.create(conversation.id, {items: [{role: "developer", content: "here is the conversation id: #{conversation.id}"}]})
    @message = Message.new(conversation_id: conversation.id, role: "user")
  end

  private

  def client
    @client ||= OpenAI::Client.new
  end
end
