class ConversationsController < ApplicationController
  def index
    if thread_id.nil?
      @thread_id = create_thread
    else
      @messages = messages_for_thread
    end
    @conversations = Conversation.order(created_at: :desc)
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
    messages = client.messages.list(thread_id: thread_id, parameters: {order: "asc"})
    messages["data"].map do |message|
      {text: message["content"][0]["text"]["value"], role: message["role"]}
    end.to_json
  end
end
