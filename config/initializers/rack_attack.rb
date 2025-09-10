class Rack::Attack
  # Throttle sign-in attempts by IP (basic stub)
  throttle("logins/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/api/v1/auth/sign_in" && req.post?
  end

  # Throttle sign-in attempts by email
  throttle("logins/email", limit: 5, period: 60) do |req|
    if req.path == "/api/v1/auth/sign_in" && req.post?
      email = req.params.dig('user', 'email')
      email if email.present?
    end
  end

  # Throttle post creation by IP
  throttle("posts/create/ip", limit: 60, period: 60) do |req|
    req.ip if req.path == "/api/v1/posts" && req.post?
  end

  # Throttle post creation by user (if authenticated)
  throttle("posts/create/user", limit: 30, period: 60) do |req|
    if req.path == "/api/v1/posts" && req.post?
      user_id = extract_user_id_from_token(req)
      user_id if user_id.present?
    end
  end

  # Throttle rating creation by IP
  throttle("ratings/create/ip", limit: 100, period: 60) do |req|
    req.ip if req.path.match?(%r{/api/v1/posts/\d+/rating}) && req.post?
  end

  # Throttle rating creation by user
  throttle("ratings/create/user", limit: 50, period: 60) do |req|
    if req.path.match?(%r{/api/v1/posts/\d+/rating}) && req.post?
      user_id = extract_user_id_from_token(req)
      user_id if user_id.present?
    end
  end

  # Throttle timeline requests by IP
  throttle("timeline/ip", limit: 200, period: 60) do |req|
    req.ip if req.path == "/api/v1/timeline" && req.get?
  end

  # Throttle timeline requests by user
  throttle("timeline/user", limit: 100, period: 60) do |req|
    if req.path == "/api/v1/timeline" && req.get?
      user_id = extract_user_id_from_token(req)
      user_id if user_id.present?
    end
  end

  # Throttle registration attempts by IP
  throttle("registrations/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  # Throttle general API requests by IP
  throttle("api/ip", limit: 1000, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Custom response for rate limited requests
  self.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_discriminator']
    match_type = env['rack.attack.matched']
    
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{
        error: {
          code: 'rate_limit_exceeded',
          message: 'Too many requests. Please try again later.',
          retry_after: 60
        }
      }.to_json]
    ]
  end

  private

  def self.extract_user_id_from_token(req)
    auth_header = req.get_header('HTTP_AUTHORIZATION')
    return nil unless auth_header&.start_with?('Bearer ')

    token = auth_header.split(' ').last
    return nil unless token&.start_with?('jwt_token_placeholder_')

    user_id_str = token.split('_').last
    user_id_str.to_i if user_id_str.match?(/\A\d+\z/)
  end
end
