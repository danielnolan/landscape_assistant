class MessagesController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(message_params).create
    @assistant_message = Message.new(role: "assistant", content: "Thinking ...", id: @message.id, thread_id: @message.thread_id)
    CreateRunJob.perform_later(@message.id, @message.thread_id)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :thread_id).merge(role: "user")
  end
end
