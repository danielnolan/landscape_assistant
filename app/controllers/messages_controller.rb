class MessagesController < ApplicationController
  include ActionController::Live
  skip_before_action :verify_authenticity_token

  def create
    response.headers["Content-Type"] = "text/event-stream"
    sse = SSE.new(response.stream, retry: 300, event: "event-name")
    Assistants::Message.new(params).create
    Assistants::Run.new(sse, params[:thread_id]).stream
  ensure
    sse.close
  end
end
