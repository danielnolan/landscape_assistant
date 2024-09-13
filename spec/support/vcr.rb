VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.ignore_hosts "chromedriver.storage.googleapis.com"
  Rails.application.credentials.config.each do |k, v|
    if v.is_a?(Hash)
      v.each do |kk, vv|
        config.filter_sensitive_data("<#{kk}>") { vv }
      end
    else
      config.filter_sensitive_data("<#{k}>") { v }
    end
  end
end
