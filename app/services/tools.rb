class Tools
  def get_weather(arguments)
    weather_api_key = ENV["TOMORROW_IO_API_KEY"]
    Rails.logger.info("get weather called")
    Rails.logger.info(Time.current)
    Rails.logger.info(arguments)
    url = "https://api.tomorrow.io/v4/timelines?apikey=#{weather_api_key}"
    connection = Faraday.new(url) do |builder|
      builder.adapter :async_http
    end
    headers = {
      "content-type": "application/json"
    }
    Async do
      response = connection.post(url, arguments, headers)
      Rails.logger.info(response.body)
      response.body
    end.wait
  end

  def get_local_weather_and_soil_moisture(arguments)
    Rails.logger.info("get local soil and weather called")
    Rails.logger.info(arguments)
    Rails.logger.info(Time.current)
    api_key = ENV["ECOWITT_API_KEY"]
    application_key = ENV["ECOWITT_APPLICATION_KEY"]
    mac_address = ENV["ECOWITT_MAC_ADDRESS"]
    url = "https://api.ecowitt.net/api/v3/device/real_time?application_key=#{application_key}&api_key=#{api_key}&mac=#{mac_address}"
    connection = Faraday.new(url) do |builder|
      builder.adapter :async_http
    end
    Async do
      response = connection.get(url)
      Rails.logger.info(response.body)
      response.body
    end.wait
  end

  def save_conversation(arguments)
    Rails.logger.info("save conversation called")
    Rails.logger.info(arguments)
    conversation = Conversation.new(JSON.parse(arguments))
    response = if conversation.save
      conversation.broadcast_prepend_later_to(:conversations)
      "The conversation has been saved with the title: #{conversation.title}."
    else
      "An error occurred trying to save the conversation"
    end
    Rails.logger.info(response)
    response
  end
end
