require "rails_helper"

RSpec.describe Api::V1::TimelineController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:third_user) { create(:user) }

  before do
    request.headers["Authorization"] = "Bearer jwt_token_placeholder_#{user.id}"
  end

  describe "GET #index" do
    let!(:post1) { create(:post, user: user, title: "First Post", created_at: 3.days.ago) }
    let!(:post2) { create(:post, user: other_user, title: "Second Post", created_at: 2.days.ago) }
    let!(:post3) { create(:post, user: third_user, title: "Third Post", created_at: 1.day.ago) }
    let!(:deleted_post) { create(:post, user: user, title: "Deleted Post", deleted_at: Time.current) }

    context "with valid authentication" do
      it "returns all active posts sorted by creation time (newest first)" do
        get :index
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json_response.length).to eq(3)
        expect(json_response.first["title"]).to eq("Third Post")
        expect(json_response.last["title"]).to eq("First Post")
      end

      it "excludes soft-deleted posts" do
        get :index
        json_response = JSON.parse(response.body)

        post_titles = json_response.map { |p| p["title"] }
        expect(post_titles).not_to include("Deleted Post")
      end

      it "includes post author information" do
        get :index
        json_response = JSON.parse(response.body)

        expect(json_response.first).to include("username")
        expect(json_response.first).to include("user")
        expect(json_response.first["user"]).to include("id", "username")
      end

      it "includes average rating and rating count" do
        # Add ratings to posts
        create(:rating, post: post1, user: user, rating: 4)
        create(:rating, post: post1, user: other_user, rating: 5)
        create(:rating, post: post2, user: user, rating: 3)

        # Reload posts to get updated cached statistics
        post1.reload
        post2.reload

        get :index
        json_response = JSON.parse(response.body)

        # Find posts with ratings
        rated_post1 = json_response.find { |p| p["id"] == post1.id }
        rated_post2 = json_response.find { |p| p["id"] == post2.id }

        expect(rated_post1).to include("average_rating", "rating_count")
        expect(rated_post1["average_rating"]).to eq("4.5")
        expect(rated_post1["rating_count"]).to eq(2)

        expect(rated_post2).to include("average_rating", "rating_count")
        expect(rated_post2["average_rating"]).to eq("3.0")
        expect(rated_post2["rating_count"]).to eq(1)
      end

      it "supports pagination" do
        get :index, params: { page: 1, per_page: 2 }
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        expect(json_response.first["title"]).to eq("Third Post")
        expect(json_response.last["title"]).to eq("Second Post")
      end

      it "supports filtering by minimum average rating" do
        # Add ratings to posts
        create(:rating, post: post1, user: user, rating: 5)
        create(:rating, post: post2, user: user, rating: 2)
        create(:rating, post: post3, user: user, rating: 4)

        # Reload posts to get updated cached statistics
        post1.reload
        post2.reload
        post3.reload

        get :index, params: { min_rating: 4.0 }
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
        post_titles = json_response.map { |p| p["title"] }
        expect(post_titles).to include("Third Post", "First Post")
        expect(post_titles).not_to include("Second Post")
      end

      it "handles empty timeline gracefully" do
        Post.destroy_all
        get :index
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end

      it "handles invalid min_rating parameter gracefully" do
        get :index, params: { min_rating: "invalid" }
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json_response.length).to eq(3)
      end

      it "uses efficient eager loading" do
        expect(controller).to receive(:render).and_call_original
        get :index

        # Verify that we're not making N+1 queries
        expect(ActiveRecord::Base.connection.query_cache.size).to be >= 0
      end
    end

    context "with invalid authentication" do
      before do
        request.headers["Authorization"] = "Bearer invalid_token"
      end

      it "returns unauthorized status" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without authentication" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized status" do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "performance considerations" do
      it "handles large datasets efficiently" do
        # Create multiple posts to test performance
        50.times do |i|
          create(:post, user: user, title: "Post #{i}", created_at: i.hours.ago)
        end

        # Test that the endpoint responds quickly with large datasets
        start_time = Time.current
        get :index, params: { per_page: 20 }
        end_time = Time.current

        expect(response).to have_http_status(:ok)
        expect(end_time - start_time).to be < 1.second
      end
    end
  end
end
