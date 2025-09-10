require 'rails_helper'

RSpec.describe Api::V1::RatingsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:test_post) { create(:post, user: user) }
  let(:other_user_token) { "jwt_token_placeholder_#{other_user.id}" }
  let(:invalid_token) { "invalid_token" }

  before do
    request.headers['Authorization'] = "Bearer jwt_token_placeholder_#{user.id}"
  end

  describe 'GET #show' do
    context 'when user has rated the post' do
      let!(:rating) { create(:rating, user: user, post: test_post, rating: 4) }

      it 'returns the user\'s rating' do
        get :show, params: { post_id: test_post.id }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to include(
          'id' => rating.id,
          'user_id' => user.id,
          'post_id' => test_post.id,
          'rating' => 4
        )
      end
    end

    context 'when user has not rated the post' do
      it 'returns 404 with error message' do
        get :show, params: { post_id: test_post.id }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'No rating found' })
      end
    end

    context 'when post does not exist' do
      it 'returns 404' do
        get :show, params: { post_id: 99999 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when not authenticated' do
      before { request.headers['Authorization'] = "Bearer #{invalid_token}" }

      it 'returns 401 unauthorized' do
        get :show, params: { post_id: test_post.id }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        post_id: test_post.id,
        rating: { rating: 4 }
      }
    end

    context 'with valid parameters' do
      it 'creates a new rating' do
        expect {
          post :create, params: valid_params
        }.to change(Rating, :count).by(1)

        expect(response).to have_http_status(:created)
        rating = JSON.parse(response.body)
        expect(rating).to include(
          'user_id' => user.id,
          'post_id' => test_post.id,
          'rating' => 4
        )
      end

      it 'updates post cached statistics' do
        post :create, params: valid_params

        test_post.reload
        expect(test_post.average_rating).to eq(4.0)
        expect(test_post.rating_count).to eq(1)
      end

      it 'associates rating with current user' do
        post :create, params: valid_params

        rating = Rating.last
        expect(rating.user).to eq(user)
        expect(rating.post).to eq(test_post)
      end
    end

    context 'with invalid rating value' do
      let(:invalid_params) do
        {
          post_id: test_post.id,
          rating: { rating: 6 }
        }
      end

      it 'returns 422 with validation errors' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when user already rated the post' do
      let!(:existing_rating) { create(:rating, user: user, post: test_post, rating: 3) }

      it 'returns 422 with validation errors' do
        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when post does not exist' do
      let(:invalid_params) do
        {
          post_id: 99999,
          rating: { rating: 4 }
        }
      end

      it 'returns 404' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when not authenticated' do
      before { request.headers['Authorization'] = "Bearer #{invalid_token}" }

      it 'returns 401 unauthorized' do
        post :create, params: valid_params

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:rating) { create(:rating, user: user, post: test_post, rating: 3) }
    let(:update_params) do
      {
        post_id: test_post.id,
        rating: { rating: 5 }
      }
    end

    context 'with valid parameters' do
      it 'updates the rating' do
        patch :update, params: update_params

        expect(response).to have_http_status(:ok)
        rating.reload
        expect(rating.rating).to eq(5)

        response_data = JSON.parse(response.body)
        expect(response_data).to include(
          'id' => rating.id,
          'user_id' => user.id,
          'post_id' => test_post.id,
          'rating' => 5
        )
      end

      it 'updates post cached statistics' do
        patch :update, params: update_params

        test_post.reload
        expect(test_post.average_rating).to eq(5.0)
        expect(test_post.rating_count).to eq(1)
      end
    end

    context 'with invalid rating value' do
      let(:invalid_params) do
        {
          post_id: test_post.id,
          rating: { rating: 0 }
        }
      end

      it 'returns 422 with validation errors' do
        patch :update, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when rating does not exist' do
      let(:non_existent_params) do
        {
          post_id: test_post.id,
          rating: { rating: 5 }
        }
      end

      before { rating.destroy }

      it 'returns 404' do
        patch :update, params: non_existent_params

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when post does not exist' do
      let(:invalid_params) do
        {
          post_id: 99999,
          rating: { rating: 5 }
        }
      end

      it 'returns 404' do
        patch :update, params: invalid_params

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when not authenticated' do
      before { request.headers['Authorization'] = "Bearer #{invalid_token}" }

      it 'returns 401 unauthorized' do
        patch :update, params: update_params

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:rating) { create(:rating, user: user, post: test_post, rating: 4) }

    context 'when rating exists' do
      it 'deletes the rating' do
        expect {
          delete :destroy, params: { post_id: test_post.id }
        }.to change(Rating, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it 'updates post cached statistics' do
        delete :destroy, params: { post_id: test_post.id }

        test_post.reload
        expect(test_post.average_rating).to eq(0.0)
        expect(test_post.rating_count).to eq(0)
      end
    end

    context 'when rating does not exist' do
      before { rating.destroy }

      it 'returns 404' do
        delete :destroy, params: { post_id: test_post.id }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when post does not exist' do
      it 'returns 404' do
        delete :destroy, params: { post_id: 99999 }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to include('error')
      end
    end

    context 'when not authenticated' do
      before { request.headers['Authorization'] = "Bearer #{invalid_token}" }

      it 'returns 401 unauthorized' do
        delete :destroy, params: { post_id: test_post.id }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe 'multiple users rating same post' do
    let(:user2) { create(:user) }
    let(:user2_token) { "jwt_token_placeholder_#{user2.id}" }

    it 'allows multiple users to rate the same post' do
      # User 1 rates the post
      post :create, params: { post_id: test_post.id, rating: { rating: 4 } }
      expect(response).to have_http_status(:created)

      # User 2 rates the same post
      request.headers['Authorization'] = "Bearer #{user2_token}"
      post :create, params: { post_id: test_post.id, rating: { rating: 5 } }
      expect(response).to have_http_status(:created)

      # Check post statistics
      test_post.reload
      expect(test_post.rating_count).to eq(2)
      expect(test_post.average_rating).to eq(4.5)
    end

    it 'prevents same user from rating post twice' do
      # First rating
      post :create, params: { post_id: test_post.id, rating: { rating: 4 } }
      expect(response).to have_http_status(:created)

      # Second rating by same user should fail
      post :create, params: { post_id: test_post.id, rating: { rating: 5 } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'edge cases' do
    context 'with soft-deleted post' do
      let(:deleted_post) { create(:post, user: user, deleted_at: Time.current) }

      it 'returns 404 for soft-deleted posts' do
        get :show, params: { post_id: deleted_post.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with missing rating parameter' do
      it 'returns 422 for missing rating' do
        post :create, params: { post_id: test_post.id }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
