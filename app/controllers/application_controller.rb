class ApplicationController < ActionController::Base
  helper_method :assistant_name
  def assistant_name
    assistant_id = Rails.application.credentials.open_ai.dig("assistant_id")
    assistant = client.assistants.retrieve(id: assistant_id)
    assistant["name"]
  end
end
