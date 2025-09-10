class Rack::Attack
  # Throttle sign-in attempts by IP (basic stub)
  throttle("logins/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/api/v1/auth/sign_in" && req.post?
  end

  throttle("posts/create/ip", limit: 60, period: 60) do |req|
    req.ip if req.path == "/api/v1/posts" && req.post?
  end
end
