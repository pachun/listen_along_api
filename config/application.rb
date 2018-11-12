require_relative 'boot'

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module ListenAlongApi
  class Application < Rails::Application
    config.load_defaults 5.2
    config.api_only = true
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Flash
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore
    config.middleware.insert_before(0, Rack::Cors) do
      allow do
        origins("*")
        resource("*", headers: :any, methods: [:get, :post, :patch, :options])
      end
    end
  end
end
