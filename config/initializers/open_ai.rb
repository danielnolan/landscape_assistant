OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.open_ai.fetch(:api_key)
  config.log_errors = true 
end
