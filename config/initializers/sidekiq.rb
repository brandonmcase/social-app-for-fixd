# Configure Sidekiq
Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.config.redis_url || "redis://localhost:6379/0" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.config.redis_url || "redis://localhost:6379/0" }
end

# Configure Sidekiq web UI (optional, for development)
if Rails.env.development?
  require "sidekiq/web"
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, "admin") &&
      ActiveSupport::SecurityUtils.secure_compare(password, "password")
  end
end
