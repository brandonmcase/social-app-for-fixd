require 'rails_helper'

RSpec.describe 'API::V1::Posts', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { "jwt_token_placeholder_#{user.id}" }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/posts' do
    let!(:posts) { create_list(:post, 3, user: user) }
    let!(:other_posts) { create_list(:post, 2, user: other_user) }

    context 'with valid authentication' do
      it 'returns 200 status' do
        get '/api/v1/posts', headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns all active posts' do
        get '/api/v1/posts', headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(5)
      end

      it 'includes post data with username' do
        get '/api/v1/posts', headers: headers
        json_response = JSON.parse(response.body)

        post_data = json_response.first
        expect(post_data).to include('id', 'title', 'body', 'view_count', 'average_rating', 'rating_count', 'created_at', 'username')
      end

      it 'orders posts by created_at desc' do
        get '/api/v1/posts', headers: headers
        json_response = JSON.parse(response.body)

        created_at_times = json_response.map { |post| Time.parse(post['created_at']) }
        expect(created_at_times).to eq(created_at_times.sort.reverse)
      end

      it 'supports pagination' do
        get '/api/v1/posts', params: { page: 1, per_page: 2 }, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response.length).to eq(2)
      end
    end

    context 'without authentication' do
      it 'returns 401 status' do
        get '/api/v1/posts'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/posts/:id' do
    let(:post) { create(:post, user: user) }

    context 'with valid authentication' do
      it 'returns 200 status' do
        get "/api/v1/posts/#{post.id}", headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns post data' do
        get "/api/v1/posts/#{post.id}", headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response).to include('id', 'title', 'body', 'view_count', 'average_rating', 'rating_count', 'created_at', 'username')
        expect(json_response['id']).to eq(post.id)
        expect(json_response['title']).to eq(post.title)
      end

      it 'increments view count' do
        expect {
          get "/api/v1/posts/#{post.id}", headers: headers
        }.to change { post.reload.view_count }.by(1)
      end
    end

    context 'with non-existent post' do
      it 'returns 404 status' do
        get '/api/v1/posts/99999', headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with deleted post' do
      let(:deleted_post) { create(:post, user: user, deleted_at: Time.current) }

      it 'returns 404 status' do
        get "/api/v1/posts/#{deleted_post.id}", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/posts' do
    let(:valid_params) do
      {
        post: {
          title: 'Test Post',
          body: 'This is a test post body'
        }
      }
    end

    let(:invalid_params) do
      {
        post: {
          title: '',
          body: 'x' * 1001
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new post' do
        expect {
          post '/api/v1/posts', params: valid_params, headers: headers
        }.to change(Post, :count).by(1)
      end

      it 'returns 201 status' do
        post '/api/v1/posts', params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it 'returns created post data' do
        post '/api/v1/posts', params: valid_params, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response).to include('id', 'title', 'body')
        expect(json_response['title']).to eq('Test Post')
        expect(json_response['body']).to eq('This is a test post body')
      end

      it 'associates post with current user' do
        post '/api/v1/posts', params: valid_params, headers: headers
        json_response = JSON.parse(response.body)

        created_post = Post.find(json_response['id'])
        expect(created_post.user).to eq(user)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a post' do
        expect {
          post '/api/v1/posts', params: invalid_params, headers: headers
        }.not_to change(Post, :count)
      end

      it 'returns 422 status' do
        post '/api/v1/posts', params: invalid_params, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns validation errors' do
        post '/api/v1/posts', params: invalid_params, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response['error']).to be_present
      end
    end

    context 'without authentication' do
      it 'returns 401 status' do
        post '/api/v1/posts', params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/posts/:id' do
    let(:post) { create(:post, user: user) }
    let(:valid_params) do
      {
        post: {
          title: 'Updated Title',
          body: 'Updated body content'
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the post' do
        patch "/api/v1/posts/#{post.id}", params: valid_params, headers: headers
        post.reload

        expect(post.title).to eq('Updated Title')
        expect(post.body).to eq('Updated body content')
      end

      it 'returns 200 status' do
        patch "/api/v1/posts/#{post.id}", params: valid_params, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns updated post data' do
        patch "/api/v1/posts/#{post.id}", params: valid_params, headers: headers
        json_response = JSON.parse(response.body)

        expect(json_response['title']).to eq('Updated Title')
        expect(json_response['body']).to eq('Updated body content')
      end
    end

    context 'with other user\'s post' do
      let(:other_post) { create(:post, user: other_user) }

      it 'returns 403 status' do
        patch "/api/v1/posts/#{other_post.id}", params: valid_params, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/posts/:id' do
    let(:post) { create(:post, user: user) }

    context 'with valid post' do
      it 'soft deletes the post' do
        delete "/api/v1/posts/#{post.id}", headers: headers
        post.reload

        expect(post.deleted_at).to be_present
      end

      it 'returns 204 status' do
        delete "/api/v1/posts/#{post.id}", headers: headers
        expect(response).to have_http_status(:no_content)
      end

      it 'does not permanently delete the post' do
        post # Ensure post is created
        expect {
          delete "/api/v1/posts/#{post.id}", headers: headers
        }.not_to change(Post, :count)
      end
    end

    context 'with other user\'s post' do
      let(:other_post) { create(:post, user: other_user) }

      it 'returns 403 status' do
        delete "/api/v1/posts/#{other_post.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
