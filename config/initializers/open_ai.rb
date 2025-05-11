OpenAI.configure do |config|
  config.access_token = ENV["OPEN_AI_API_KEY"]
  config.log_errors = true 
end
