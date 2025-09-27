module Tools
  class GetWeather < OpenAI::BaseModel
    Fields = OpenAI::EnumOf[
      "temperature",
      "humidity",
      "pressureSeaLevel",
      "windSpeed",
      "windDirection",
      "weatherCode",
      "visibility",
      "pollutantO3",
      "windGust",
      "cloudCover",
      "precipitationType",
      "precipitationProbability",
      "pollutantCO",
      "mepIndex",
      "mepHealthConcern",
      "mepPrimaryPollutant",
      "cloudBase",
      "cloudCeiling",
      "cloudCover",
      "dewPoint",
      "epaIndex",
      "epaHealthConcern",
      "epaPrimaryPollutant",
      "temperatureApparent",
      "fireIndex",
      "pollutantNO2",
      "pollutantO3",
      "particulateMatter10",
      "particulateMatter25",
      "grassIndex",
      "treeIndex",
      "weedIndex",
      "pressureSurfaceLevel",
      "solarGHI",
      "pollutantSO2",
      "uvIndex",
      "uvHealthConcern",
      "windGust"
    ]

    TimeSteps = OpenAI::EnumOf[
      "1h",
      "1d",
      "current"
    ]

    required :location,
      String,
      doc: "Latitude and longitude separated by a comma"

    required :units,
      OpenAI::EnumOf[:imperial, :metric],
      doc: "Units to display measurements"

    required :fields,
      OpenAI::ArrayOf[Fields, doc: "weather measurements"],
      doc: "Fields is an array of strings for the API to return in it's response"

    required :timesteps,
      OpenAI::ArrayOf[TimeSteps],
      nil?: true,
      doc: "array of timestep strings. The timesteps can be current, 1d or 1h. Current for realtime, 1h for hourly, 1d for daily"

    required :startTime,
      String,
      nil?: true,
      doc: "Start time can be 'now', 'nowPlusXm/h/d', 'nowMinusXm/h/d' (defaults to now)."

    required :endTime,
      String,
      nil?: true,
      doc: "End time can be 'now', 'nowPlusXm/h/d', 'nowMinusXm/h/d' (defaults to nowPlus6h). Can't be more than 5 days in the future. Must be greater than startTime."

    def call(arguments:)
      Rails.logger.info("Calling GetWeather with arguments: #{arguments}")
      weather_api_key = ENV["TOMORROW_IO_API_KEY"]
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
  end
end
