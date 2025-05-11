class ApplicationController < ActionController::Base
  helper_method :assistant_name
  def assistant_name
    assistant_id = ENV["OPEN_AI_ASSISTANT_ID"]
    assistant = client.assistants.retrieve(id: assistant_id)
    assistant["name"]
  end
end
