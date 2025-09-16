class ApplicationController < ActionController::Base
  def open_ai_client
    OpenAIClient.instance.client
  end
  helper_method :openai_client
end
