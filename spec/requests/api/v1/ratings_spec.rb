require 'rails_helper'

RSpec.describe 'API::V1::Ratings', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:test_post) { create(:post, user: other_user) }
  let(:token) { "jwt_token_placeholder_#{user.id}" }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/posts/:post_id/rating' do
    context 'when user has rated the post' do
      let!(:rating) { create(:rating, user: user, post: test_post, rating: 4) }

      it 'returns 200 status' do
        get "/api/v1/posts/#{test_post.id}/rating", headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns rating data' do
        get "/api/v1/posts/#{test_post.id}/rating", headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response).to include('id', 'rating', 'user_id', 'post_id')
        expect(json_response['rating']).to eq(4)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['post_id']).to eq(test_post.id)
      end
    end

    context 'when user has not rated the post' do
      it 'returns 404 status' do
        get "/api/v1/posts/#{test_post.id}/rating", headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found error' do
        get "/api/v1/posts/#{test_post.id}/rating", headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['error']).to eq('No rating found')
      end
    end

    context 'with non-existent post' do
      it 'returns 404 status' do
        get '/api/v1/posts/99999/rating', headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/posts/:post_id/rating' do
    let(:valid_params) do
      {
        rating: {
          rating: 5
        }
      }
    end

    let(:invalid_params) do
      {
        rating: {
          rating: 6
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new rating' do
        expect {
          post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        }.to change(Rating, :count).by(1)
      end

      it 'returns 201 status' do
        post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it 'returns created rating data' do
        post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response).to include('id', 'rating', 'user_id', 'post_id')
        expect(json_response['rating']).to eq(5)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['post_id']).to eq(test_post.id)
      end

      it 'updates post rating statistics' do
        post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        test_post.reload
        
        expect(test_post.average_rating).to eq(5.0)
        expect(test_post.rating_count).to eq(1)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a rating' do
        expect {
          post "/api/v1/posts/#{test_post.id}/rating", params: invalid_params, headers: headers
        }.not_to change(Rating, :count)
      end

      it 'returns 422 status' do
        post "/api/v1/posts/#{test_post.id}/rating", params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns validation errors' do
        post "/api/v1/posts/#{test_post.id}/rating", params: invalid_params, headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['error']).to be_present
      end
    end

    context 'when user already rated the post' do
      let!(:existing_rating) { create(:rating, user: user, post: test_post, rating: 3) }

      it 'does not create a duplicate rating' do
        expect {
          post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        }.not_to change(Rating, :count)
      end

      it 'returns 422 status' do
        post "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'without authentication' do
      it 'returns 401 status' do
        post "/api/v1/posts/#{test_post.id}/rating", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/posts/:post_id/rating' do
    let!(:rating) { create(:rating, user: user, post: test_post, rating: 3) }
    let(:valid_params) do
      {
        rating: {
          rating: 5
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the rating' do
        patch "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        rating.reload
        
        expect(rating.rating).to eq(5)
      end

      it 'returns 200 status' do
        patch "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns updated rating data' do
        patch "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['rating']).to eq(5)
      end

      it 'updates post rating statistics' do
        patch "/api/v1/posts/#{test_post.id}/rating", params: valid_params, headers: headers
        test_post.reload
        
        expect(test_post.average_rating).to eq(5.0)
        expect(test_post.rating_count).to eq(1)
      end
    end

    context 'when user has not rated the post' do
      let(:unrated_post) { create(:post, user: other_user) }

      it 'returns 404 status' do
        patch "/api/v1/posts/#{unrated_post.id}/rating", params: valid_params, headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          rating: {
            rating: 0
          }
        }
      end

      it 'does not update the rating' do
        original_rating = rating.rating
        patch "/api/v1/posts/#{test_post.id}/rating", params: invalid_params, headers: headers
        rating.reload
        
        expect(rating.rating).to eq(original_rating)
      end

      it 'returns 422 status' do
        patch "/api/v1/posts/#{test_post.id}/rating", params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE /api/v1/posts/:post_id/rating' do
    let!(:rating) { create(:rating, user: user, post: test_post, rating: 4) }

    context 'with existing rating' do
      it 'deletes the rating' do
        expect {
          delete "/api/v1/posts/#{test_post.id}/rating", headers: headers
        }.to change(Rating, :count).by(-1)
      end

      it 'returns 204 status' do
        delete "/api/v1/posts/#{test_post.id}/rating", headers: headers
        expect(response).to have_http_status(:no_content)
      end

      it 'updates post rating statistics' do
        delete "/api/v1/posts/#{test_post.id}/rating", headers: headers
        test_post.reload
        
        expect(test_post.average_rating).to eq(0.0)
        expect(test_post.rating_count).to eq(0)
      end
    end

    context 'when user has not rated the post' do
      let(:unrated_post) { create(:post, user: other_user) }

      it 'returns 404 status' do
        delete "/api/v1/posts/#{unrated_post.id}/rating", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end