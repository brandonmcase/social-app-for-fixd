module JwtTokenHelper
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      username: user.username,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }

    JWT.encode(payload, jwt_secret, 'HS256')
  end

  def jwt_secret
    ENV.fetch('JWT_SECRET_KEY', 'development_secret_key_change_in_production')
  end

  def auth_headers(user)
    token = generate_jwt_token(user)
    { 'Authorization' => "Bearer #{token}" }
  end
end
