 module Tools
   class GetLocalWeatherAndSoilMoisture < OpenAI::BaseModel
     def call(arguments: {})
       Rails.logger.info("GetLocalWeatherAndSoilMoisture called")
       api_key = ENV["ECOWITT_API_KEY"]
       application_key = ENV["ECOWITT_APPLICATION_KEY"]
       mac_address = ENV["ECOWITT_MAC_ADDRESS"]
       params = "application_key=#{application_key}&api_key=#{api_key}&mac=#{mac_address}"
       url = "https://api.ecowitt.net/api/v3/device/real_time?#{params}"
       connection = Faraday.new(url) do |builder|
         builder.adapter :async_http
       end
       Async do
         response = connection.get(url)
         Rails.logger.info(response.body)
         response.body
       end.wait
     end
   end
 end
