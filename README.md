# Landscape Assistant
This is for my ChatGPT powered landscape agent.
This uses the new responses API and makes use of a saved prompt.
Create a promt via the OpenAI API UI and get it's id and create a
open API key to use for the app.
Create an API key at https://tomorrow.io to use for the weather
forecast.
If you have Ecowitt an weather station or soil moisture sensors you
can pull in that data too by providing your Ecowitt API key and
MAC address.

## Dependencies
* Rails 8.0.3
* Ruby 3.4.5
* PostgreSQL 14
* Redis 7.2.5

## Running the app
* run `bin/setup`
* You need to create a .env file

``` env
OPEN_AI_API_KEY=
OPEN_AI_PROMPT_ID=
ECOWITT_API_KEY=
ECOWITT_APPLICATION_KEY=
ECOWITT_MAC_ADDRESS=
TOMORROW_IO_API_KEY=
SECRET_KEY_BASE=
LANDSCAPE_ASSISTANT_DATABASE_USER=
LANDSCAPE_ASSISTANT_DATABASE_PASSWORD=
