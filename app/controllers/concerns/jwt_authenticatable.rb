module JwtAuthenticatable
  extend ActiveSupport::Concern

  private

  def generate_jwt_token(user)
    # Generate a real JWT token with user information
    payload = {
      user_id: user.id,
      email: user.email,
      username: user.username,
      exp: 24.hours.from_now.to_i, # Token expires in 24 hours
      iat: Time.current.to_i # Issued at
    }

    JWT.encode(payload, jwt_secret, "HS256")
  end

  def decode_jwt_token(token)
    JWT.decode(token, jwt_secret, true, { algorithm: "HS256" })[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def jwt_secret
    ENV.fetch("JWT_SECRET_KEY", "development_secret_key_change_in_production")
  end
end
