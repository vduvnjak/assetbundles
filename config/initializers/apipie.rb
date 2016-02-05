Apipie.configure do |config|
  config.app_name                = "Asset Bundle and Content Hosting Service (ABACUS)"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/docs"
  config.app_info["1.0"]          = "
    This service provides content routing and catalog APIs for Unity game clients.
  "
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
end
