class ConversationsController < ApplicationController
  def index
    @messages = Message.messages_for_thread(thread_id)
    @thread_id = Conversation.new.create_thread if thread_id.nil?
    @conversations = Conversation.order(created_at: :desc)
    @message = Message.new
  end

  private

  def thread_id
    @thread_id ||= params[:thread_id]
  end
end
