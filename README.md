# Landscape Assistant
This is for my ChatGPT powered landscape assistant, but you could use it
with any assitant you want.
Create an assistant via the OpenAI API UI and get it's id and create a
open API key to use for the app.
Create an API key at https://tomorrow.io to use for the weather
forecast.

## Dependencies
* Rails 8.0.2
* Ruby 3.4.1
* PostgreSQL 14
* Redis 7.2.5

## Running the app
* run `bin/setup`
* You need to create a .env file

``` env
OPEN_AI_API_KEY=
OPEN_AI_ASSISTANT_ID=
ECOWITT_API_KEY=
ECOWITT_APPLICATION_KEY=
ECOWITT_MAC_ADDRESS=
TOMORROW_IO_API_KEY=
SECRET_KEY_BASE=
LANDSCAPE_ASSISTANT_DATABASE_USER=
LANDSCAPE_ASSISTANT_DATABASE_PASSWORD=
