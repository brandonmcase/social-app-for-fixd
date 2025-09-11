# lib/tasks/api_test.rake
require "open3"
require "json"
require "faker"
require "tempfile"

namespace :api do
  desc "Run end-to-end API tests across all endpoints"
  task test: :environment do
    base = ENV["API_BASE_URL"] || "http://127.0.0.1:3000"
    puts "== Running API tests against #{base} =="

    # ------------------------------- helpers ---------------------------------
    def run_curl(cmd)
      stdout, stderr, status = Open3.capture3(cmd)
      puts "\n$ #{cmd}"
      puts "→ exit: #{status.exitstatus}"
      puts "→ stderr:\n#{stderr}" unless stderr.nil? || stderr.empty?
      [ stdout, status.exitstatus ]
    end

    def fail!(msg)
      puts "❌ #{msg}"
      exit 1
    end

    # Health check (ok if 404 when no /up)
    hc = %Q(curl -sS --max-time 2 -o /dev/null -w "%{http_code}" #{base}/up || true)
    code = `#{hc}`.strip
    puts "Health check: HTTP #{code} (continuing)"

    # ----------------------------- test user ---------------------------------
    email    = Faker::Internet.unique.email
    username = Faker::Internet.unique.username(specifier: 6..10)
    password = "password"

    puts "Generated user: #{email} / #{username}"

    # ------------------------------ register ---------------------------------
    register = %Q(curl -sS --fail-with-body -X POST #{base}/api/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{"user":{"email":"#{email}","username":"#{username}","password":"#{password}","password_confirmation":"#{password}"}}')
    reg_body, reg_code = run_curl(register)
    fail!("registration failed") unless reg_code.zero?
    puts "Register response:\n#{reg_body}"

    # -------------------------------- login ----------------------------------
    headers = Tempfile.new("login_headers")
    bodyf   = Tempfile.new("login_body")
    login   = %Q(curl -sS --fail-with-body -i -D #{headers.path} -o #{bodyf.path} -X POST #{base}/api/v1/auth/sign_in \
      -H "Content-Type: application/json" \
      -d '{"user":{"email":"#{email}","password":"#{password}"}}')
    _login_body, login_code = run_curl(login)
    fail!("login failed") unless login_code.zero?

    token = JSON.parse(reg_body)["token"] || JSON.parse(reg_body).dig("data", "token")

    fail!("could not extract JWT") if token.nil?
    puts "✅ JWT: #{token[0, 24]}..."

    # -------------------------------- me -------------------------------------
    me = %Q(curl -sS --fail-with-body #{base}/api/v1/auth/me -H "Authorization: Bearer #{token}")
    me_body, me_code = run_curl(me)
    fail!("auth/me failed") unless me_code.zero?
    puts "Me:\n#{me_body}"

    # ------------------------------ timeline ---------------------------------
    tl1 = %Q(curl -sS --fail-with-body "#{base}/api/v1/timeline?page=1&per_page=5" -H "Authorization: Bearer #{token}")
    _tl1_body, tl1_code = run_curl(tl1)
    fail!("timeline failed") unless tl1_code.zero?

    tl2 = %Q(curl -sS --fail-with-body "#{base}/api/v1/timeline?page=1&per_page=5&min_rating=3" -H "Authorization: Bearer #{token}")
    _tl2_body, tl2_code = run_curl(tl2)
    fail!("timeline with min_rating failed") unless tl2_code.zero?

    # ----------------------------- create post -------------------------------
    created_post_id = nil
    create_post = %Q(curl -sS --fail-with-body -X POST #{base}/api/v1/posts \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer #{token}" \
      -d '{
        "post":{
          "title":"Hello from #{username}",
          "body":"This is a test post at #{Time.now.utc.iso8601}",
          "metadata":{
            "language":"en",
            "tags":["rails","postgres","jsonb"],
            "flags":{"featured":true},
            "category":"demo",
            "source":"api_test_rake",
            "score": 4.2
          }
        }
      }')
    post_body, post_code = run_curl(create_post)
    fail!("create post failed") unless post_code.zero?
    begin
      created_post_id = JSON.parse(post_body).dig("data", "id") ||
                        JSON.parse(post_body).dig("id")
    rescue JSON::ParserError
      created_post_id = nil
    end
    puts "Created post id: #{created_post_id || "(could not parse; continuing)"}"

    # ------------------------------ list posts -------------------------------
    list_posts = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts?page=1&per_page=5" -H "Authorization: Bearer #{token}")
    _lp_body, lp_code = run_curl(list_posts)
    fail!("list posts failed") unless lp_code.zero?

    # JSONB filters
    list_lang = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts?language=en" -H "Authorization: Bearer #{token}")
    _ll_body, ll_code = run_curl(list_lang)
    fail!("list posts language filter failed") unless ll_code.zero?

    list_tag = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts?tag=rails" -H "Authorization: Bearer #{token}")
    _lt_body, lt_code = run_curl(list_tag)
    fail!("list posts tag filter failed") unless lt_code.zero?

    list_feat = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts?featured=true" -H "Authorization: Bearer #{token}")
    _lf_body, lf_code = run_curl(list_feat)
    fail!("list posts featured filter failed") unless lf_code.zero?

    list_score = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts?min_score=3" -H "Authorization: Bearer #{token}")
    _ls_body, ls_code = run_curl(list_score)
    fail!("list posts min_score filter failed") unless ls_code.zero?

    # -------------------------------- show/update ----------------------------
    if created_post_id
      show_post = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts/#{created_post_id}" -H "Authorization: Bearer #{token}")
      _sp_body, sp_code = run_curl(show_post)
      fail!("show post failed") unless sp_code.zero?

      update_post = %Q(curl -sS --fail-with-body -X PATCH #{base}/api/v1/posts/#{created_post_id} \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer #{token}" \
        -d '{"post":{"title":"[updated] Hello from #{username}"}}')
      _up_body, up_code = run_curl(update_post)
      fail!("update post failed") unless up_code.zero?
    else
      puts "⚠️  Skipping show/update — no post id parsed."
    end

    # -------------------------------- ratings --------------------------------
    if created_post_id
      get_rating = %Q(curl -sS --fail-with-body "#{base}/api/v1/posts/#{created_post_id}/rating" -H "Authorization: Bearer #{token}")
      _gr_body, gr_code = run_curl(get_rating)
      # GET may 404 if none exists — that's okay

      create_rating = %Q(curl -sS --fail-with-body -X POST #{base}/api/v1/posts/#{created_post_id}/rating \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer #{token}" \
        -d '{"rating":{"rating":5}}')
      _cr_body, cr_code = run_curl(create_rating)
      fail!("create rating failed") unless cr_code.zero?

      update_rating = %Q(curl -sS --fail-with-body -X PATCH #{base}/api/v1/posts/#{created_post_id}/rating \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer #{token}" \
        -d '{"rating":{"stars":4}}')
      _ur_body, ur_code = run_curl(update_rating)
      fail!("update rating failed") unless ur_code.zero?

      delete_rating = %Q(curl -sS --fail-with-body -X DELETE "#{base}/api/v1/posts/#{created_post_id}/rating" -H "Authorization: Bearer #{token}")
      _dr_body, dr_code = run_curl(delete_rating)
      fail!("delete rating failed") unless dr_code.zero?
    end

    # -------------------------------- search ---------------------------------
    search = %Q(curl -sS --fail-with-body "#{base}/api/v1/search?q=hello&page=1&per_page=5" -H "Authorization: Bearer #{token}")
    _se_body, se_code = run_curl(search)
    fail!("search failed") unless se_code.zero?

    # -------------------------------- delete (soft) --------------------------
    if created_post_id
      delete_post = %Q(curl -sS --fail-with-body -X DELETE "#{base}/api/v1/posts/#{created_post_id}" -H "Authorization: Bearer #{token}")
      _dp_body, dp_code = run_curl(delete_post)
      fail!("delete post failed") unless dp_code.zero?
    end

    # -------------------------------- sign out -------------------------------
    sign_out = %Q(curl -sS --fail-with-body -X DELETE #{base}/api/v1/auth/sign_out -H "Authorization: Bearer #{token}")
    _so_body, so_code = run_curl(sign_out)
    fail!("sign out failed") unless so_code.zero?

    puts "\n== ✅ All endpoint checks completed =="
  end
end
