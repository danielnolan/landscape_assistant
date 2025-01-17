class ConversationsController < ApplicationController
  def index
    if thread_id.nil?
      @thread_id = create_thread
    end
    @messages = messages_for_thread
    @conversations = Conversation.order(created_at: :desc)
    @message = Message.new
  end

  private

  def thread_id
    @thread_id ||= params[:thread_id]
  end

  def client
    @client ||= OpenAI::Client.new
  end

  def create_thread
    response = client.threads.create
    response["id"]
  end

  def messages_for_thread
    return [] if thread_id.nil?
    # TODO: move this to the message model
    messages = client.messages.list(thread_id: thread_id, parameters: {order: "asc"})
    messages["data"].map do |message|
      Message.new(content: message["content"][0]["text"]["value"], role: message["role"])
    end
  end
end
