class MessagesController < ApplicationController
  def index
    @message = Message.new(conversation_id: conversation.id, role: "user")
    @conversations = Conversation.order(created_at: :desc)
    @messages = messages
  end

  def create
    @message = Message.new(message_params)
    @assistant_message = Message.new(role: "assistant", content: "Thinking ...", id: @message.id)
    CreateResponseJob.perform_later(params: @message.attributes)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def conversation
    @conversation ||= if params[:conversation_id].present?
      open_ai_client.conversations.retrieve(params[:conversation_id])
    else
      convo = open_ai_client.conversations.create
      open_ai_client.conversations.items.create(
        convo.id,
        {items: [{role: "developer", content: "here is the conversation id: #{convo.id}"}]}
      )
      convo
    end
  end

  def messages
    items = open_ai_client.conversations.items.list(conversation.id, limit: 100)
    items.data.reverse.filter_map do |item|
      if item.is_a?(OpenAI::Models::Conversations::Message) && item.role.in?([:user, :assistant])
        Message.new(
          id: item.id,
          role: item.role,
          content: item.content.first[:text],
          conversation_id: conversation.id
        )
      end
    end
  end

  def message_params
    params.require(:message).permit(:content, :conversation_id).merge(role: "user", id: Random.new.rand(1000000))
  end
end
