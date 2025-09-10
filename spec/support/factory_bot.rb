# Support file for RSpec configuration
require 'factory_bot'

# Configure FactoryBot
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
