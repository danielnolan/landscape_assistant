class AssistantFunctions
  def get_weather(arguments)
    weather_api_key = Rails.application.credentials.tomorrow_io.dig("api_key")
    Rails.logger.debug("get weather called")
    Rails.logger.debug(arguments)
    url = "https://api.tomorrow.io/v4/timelines?apikey=#{weather_api_key}"
    headers = {
      "content-type": "application/json"
    }
    response = Faraday.post(url, arguments, headers)
    Rails.logger.debug(response.body)
    response.body
  end

  def get_local_weather_and_soil_moisture(arguments)
    Rails.logger.debug("get local soil and weather called")
    Rails.logger.debug(arguments)
    ecowitt = Rails.application.credentials.ecowitt
    api_key = ecowitt.dig("api_key")
    application_key = ecowitt.dig("application_key")
    mac_address = ecowitt.dig("mac_address")
    url = "https://api.ecowitt.net/api/v3/device/real_time?application_key=#{application_key}&api_key=#{api_key}&mac=#{mac_address}"
    response = Faraday.get(url)
    Rails.logger.debug(response.body)
    response.body
  end

  def save_thread(arguments)
    Rails.logger.debug("save thread called")
    Rails.logger.debug(arguments)
    chat_thread = ChatThread.new(JSON.parse(arguments))
    response = if chat_thread.save
      # TODO: add turbo stream to broadcast to from here
      "The thread has been saved with the title: #{chat_thread.title}."
    else
      "An error occurred trying to save the thread"
    end
    Rails.logger.debug(response)
    response
  end
end
