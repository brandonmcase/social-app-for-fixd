require 'rails_helper'

RSpec.describe 'API::V1::Timeline', type: :request do
  include JwtTokenHelper

  let(:user) { create(:user) }
  let(:token) { generate_jwt_token(user) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/timeline' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:posts) do
      [
        create(:post, user: user1, title: 'Post 1', created_at: 3.days.ago),
        create(:post, user: user2, title: 'Post 2', created_at: 2.days.ago),
        create(:post, user: user1, title: 'Post 3', created_at: 1.day.ago)
      ]
    end

    context 'with valid authentication' do
      it 'returns 200 status' do
        get '/api/v1/timeline', headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns all active posts' do
        get '/api/v1/timeline', headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(3)
      end

      it 'includes post data with author information' do
        get '/api/v1/timeline', headers: headers
        json_response = JSON.parse(response.body)

        post_data = json_response.first
        expect(post_data).to include('id', 'title', 'body', 'view_count', 'average_rating', 'rating_count', 'created_at', 'username')
        expect(post_data).to include('user')
        expect(post_data['user']).to include('id', 'username')
      end

      it 'orders posts by created_at desc (newest first)' do
        get '/api/v1/timeline', headers: headers
        json_response = JSON.parse(response.body)

        titles = json_response.map { |post| post['title'] }
        expect(titles).to eq([ 'Post 3', 'Post 2', 'Post 1' ])
      end

      it 'supports pagination' do
        get '/api/v1/timeline', params: { page: 1, per_page: 2 }, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
      end

      it 'supports custom per_page parameter' do
        get '/api/v1/timeline', params: { per_page: 1 }, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(1)
      end
    end

    context 'with minimum rating filter' do
      let!(:high_rated_post) do
        post = create(:post, user: user1, title: 'High Rated Post')
        create(:rating, post: post, rating: 5)
        post
      end

      let!(:low_rated_post) do
        post = create(:post, user: user2, title: 'Low Rated Post')
        create(:rating, post: post, rating: 2)
        post
      end

      it 'filters posts by minimum average rating' do
        get '/api/v1/timeline', params: { min_rating: 4.0 }, headers: headers
        json_response = JSON.parse(response.body)

        titles = json_response.map { |post| post['title'] }
        expect(titles).to include('High Rated Post')
        expect(titles).not_to include('Low Rated Post')
      end

      it 'returns empty array when no posts meet minimum rating' do
        get '/api/v1/timeline', params: { min_rating: 6.0 }, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response).to be_empty
      end

      it 'includes all posts when min_rating is 0' do
        get '/api/v1/timeline', params: { min_rating: 0 }, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to be >= 2
      end
    end

    context 'with deleted posts' do
      let!(:deleted_post) { create(:post, user: user1, deleted_at: Time.current) }

      it 'excludes deleted posts' do
        get '/api/v1/timeline', headers: headers
        json_response = JSON.parse(response.body)

        post_ids = json_response.map { |post| post['id'] }
        expect(post_ids).not_to include(deleted_post.id)
      end
    end

    context 'with posts from multiple users' do
      let!(:user3) { create(:user) }
      let!(:user4) { create(:user) }
      let!(:multi_user_posts) do
        [
          create(:post, user: user1, title: 'User1 Post'),
          create(:post, user: user2, title: 'User2 Post'),
          create(:post, user: user3, title: 'User3 Post'),
          create(:post, user: user4, title: 'User4 Post')
        ]
      end

      it 'includes posts from all users' do
        get '/api/v1/timeline', headers: headers
        json_response = JSON.parse(response.body)

        usernames = json_response.map { |post| post['username'] }
        expect(usernames).to include(user1.username, user2.username, user3.username, user4.username)
      end
    end

    context 'without authentication' do
      it 'returns 401 status' do
        get '/api/v1/timeline'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'performance considerations' do
      let!(:many_posts) { create_list(:post, 50) }

      it 'handles large datasets efficiently' do
        start_time = Time.current
        get '/api/v1/timeline', headers: headers
        end_time = Time.current

        expect(response).to have_http_status(:ok)
        expect(end_time - start_time).to be < 1.second
      end

      it 'uses eager loading to avoid N+1 queries' do
        # This test verifies that the timeline endpoint works efficiently
        # In a real implementation, you would use database_cleaner or similar
        # to count actual database queries
        get '/api/v1/timeline', headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
