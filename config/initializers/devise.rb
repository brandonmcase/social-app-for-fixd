Devise.setup do |config|
  config.mailer_sender = ENV.fetch("DEVISE_MAILER_SENDER", "no-reply@example.com")
  require "devise/orm/active_record"

  # config.parent_controller = "ActionController::API"

  # API-only
  config.navigational_formats = []
  config.skip_session_storage = [ :http_auth, :params_auth ]

  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # JWT - Disabled for custom authentication
  # config.jwt do |jwt|
  #   jwt.secret = ENV.fetch("DEVISE_JWT_SECRET_KEY")
  #   jwt.dispatch_requests = [
  #     ["POST", %r{^/api/v1/auth/sign_in$}],
  #     ["POST", %r{^/api/v1/auth/register$}]
  #   ]
  #   jwt.revocation_requests = [
  #     ["DELETE", %r{^/api/v1/auth/sign_out$}]
  #   ]
  #   jwt.expiration_time = ENV.fetch("DEVISE_JWT_EXP_SECONDS", (60 * 60).to_s).to_i
  # end
end
