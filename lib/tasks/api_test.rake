# lib/tasks/api_test.rake
require "open3"
require "json"
require "faker"

namespace :api do
  desc "Run API tests with Faker-generated user"
  task test: :environment do
    puts "== Running API tests =="

    # Generate unique user
    email    = Faker::Internet.unique.email
    username = Faker::Internet.unique.username(specifier: 5..8)
    password = "password"

    puts "Generated test user:"
    puts "  email: #{email}"
    puts "  username: #{username}"

    # 1) Register user
    register_cmd = %Q(curl -s -X POST http://localhost:3000/api/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{"user":{"email":"#{email}","username":"#{username}","password":"#{password}","password_confirmation":"#{password}"}}')

    stdout, stderr, status = Open3.capture3(register_cmd)
    puts "\n[Register] Exit: #{status.exitstatus}"
    puts "STDOUT: #{stdout}"
    puts "STDERR: #{stderr}" unless stderr.empty?

    # 2) Login user to get JWT
    login_cmd = %Q(curl -s -X POST http://localhost:3000/api/v1/auth/sign_in \
      -H "Content-Type: application/json" \
      -d '{"user":{"email":"#{email}","password":"#{password}"}}')

    stdout, stderr, status = Open3.capture3(login_cmd)
    puts "\n[Login] Exit: #{status.exitstatus}"
    puts "STDOUT: #{stdout}"
    puts "STDERR: #{stderr}" unless stderr.empty?

    token = nil
    begin
      json = JSON.parse(stdout)
      token = json["token"] || json.dig("data", "token")
    rescue JSON::ParserError
      puts "Failed to parse login response as JSON"
    end

    if token.nil?
      puts "❌ No token received. Aborting."
      next
    end

    puts "✅ Got JWT token: #{token[0..20]}..."

    # 3) Create a post
    post_cmd = %Q(curl -s -X POST http://localhost:3000/api/v1/posts \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer #{token}" \
      -d '{"post":{"title":"Hello from #{username}","body":"This is a test post created at #{Time.now}"}}')

    stdout, stderr, status = Open3.capture3(post_cmd)
    puts "\n[Create Post] Exit: #{status.exitstatus}"
    puts "STDOUT: #{stdout}"
    puts "STDERR: #{stderr}" unless stderr.empty?

    # 4) Run a search
    search_cmd = %Q(curl -s "http://localhost:3000/api/v1/search?q=hello&page=1&per_page=5" \
      -H "Authorization: Bearer #{token}")

    stdout, stderr, status = Open3.capture3(search_cmd)
    puts "\n[Search] Exit: #{status.exitstatus}"
    puts "STDOUT: #{stdout}"
    puts "STDERR: #{stderr}" unless stderr.empty?

    puts "\n== Done =="
  end
end
