# Landscape Assistant
This is for my ChatGPT powered landscape assistant, but you could use it
with any assitant you want.
Create an assistant via the OpenAI API UI and get it's id and create a
open API key to use for the app.
Create an API key at https://tomorrow.io to use for the weather
forecast.

## Dependencies
* Ruby 3.3.2

* PostgreSQL 14

* Redis 7.2.5

## Running the app
* run `bin/setup`
* run `rails credentials:edit` and add the following secrets. If you
  don't an have ecowitt weather station, that's fine you just won't configure that
  function for your assistant.

``` yaml
open_ai:
  api_key: ""
  assistant_id: ""

ecowitt:
  api_key: ""
  application_key: ""
  mac_address: ""

tomorrow_io:
  api_key: ""
```
* run `bin/rails s` to start the server, site should be available at
  http://127.0.0.1:3000
