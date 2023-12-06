require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AllOfUsHelper
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.before_configuration do
      config_file = File.join(Rails.root, 'config', 'config.yml')
      APP_CONFIG = YAML.load(File.open(config_file))
    end

    config.custom = ActiveSupport::OrderedOptions.new
    config.custom.app_config = APP_CONFIG
    config.time_zone = 'Central Time (US & Canada)'
  end
end
