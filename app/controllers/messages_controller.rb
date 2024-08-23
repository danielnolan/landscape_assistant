class MessagesController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(message_params).create
    @assistant_message = Message.new(assistant_message_params)
    CreateRunJob.perform_later(@message.id, @message.thread_id)
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :thread_id).merge(role: "user")
  end

  def assistant_message_params
    {content: "thinking...", id: "assistant_#{@message.id}", role: "assistant"}
  end
end
