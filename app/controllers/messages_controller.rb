class MessagesController < ApplicationController
  def new
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

  def message_params
    params.require(:message).permit(:content, :conversation_id).merge(role: "user", id: Random.new.rand(1000000))
  end
end
