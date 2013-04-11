require 'action_controller/railtie'
require 'rails/test_unit/railtie'
require 'active_record'

class Application < ::Rails::Application
  config.active_support.deprecation = :stderr
end

Application.initialize!
