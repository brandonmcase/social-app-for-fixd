require 'rails_helper'

RSpec.describe Api::V1::PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:user_post) { create(:post, user: user) }
  let(:other_post) { create(:post, user: other_user) }

  before do
    # Skip authentication for testing
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:posts) { create_list(:post, 3, user: user) }
    let!(:deleted_post) { create(:post, :deleted, user: user) }

    it 'returns all active posts' do
      get :index
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(3)
    end

    it 'excludes deleted posts' do
      get :index
      json_response = JSON.parse(response.body)
      post_ids = json_response.map { |p| p['id'] }
      expect(post_ids).not_to include(deleted_post.id)
    end

    it 'includes username in response' do
      get :index
      json_response = JSON.parse(response.body)
      expect(json_response.first['username']).to eq(user.username)
    end

    it 'includes rating information in response' do
      # Add ratings to posts
      create(:rating, post: posts.first, user: user, rating: 4)
      create(:rating, post: posts.first, user: other_user, rating: 5)

      get :index
      json_response = JSON.parse(response.body)

      # Find the post with ratings in the response
      rated_post = json_response.find { |p| p['id'] == posts.first.id }

      expect(rated_post).to include('average_rating', 'rating_count')
      expect(rated_post['average_rating']).to eq('4.5')
      expect(rated_post['rating_count']).to eq(2)
    end

    it 'orders posts by created_at desc' do
      get :index
      json_response = JSON.parse(response.body)
      created_dates = json_response.map { |p| DateTime.parse(p['created_at']) }
      expect(created_dates).to eq(created_dates.sort.reverse)
    end

    it 'supports pagination' do
      get :index, params: { page: 1, per_page: 2 }
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end
  end

  describe 'GET #show' do
    it 'returns the post' do
      get :show, params: { id: user_post.id }
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(user_post.id)
      expect(json_response['title']).to eq(user_post.title)
      expect(json_response['body']).to eq(user_post.body)
    end

    it 'includes username in response' do
      get :show, params: { id: user_post.id }
      json_response = JSON.parse(response.body)
      expect(json_response['username']).to eq(user.username)
    end

    it 'includes rating information in response' do
      # Add ratings to the post
      create(:rating, post: user_post, user: user, rating: 4)
      create(:rating, post: user_post, user: other_user, rating: 5)

      # Reload the post to get updated cached statistics
      user_post.reload

      get :show, params: { id: user_post.id }
      json_response = JSON.parse(response.body)

      expect(json_response).to include('average_rating', 'rating_count')
      expect(json_response['average_rating']).to eq('4.5')
      expect(json_response['rating_count']).to eq(2)
    end

    it 'increments view count' do
      expect {
        get :show, params: { id: user_post.id }
      }.to change { user_post.reload.view_count }.by(1)
    end

    it 'returns 404 for non-existent post' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for deleted post' do
      deleted_post = create(:post, :deleted, user: user)
      get :show, params: { id: deleted_post.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
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
          body: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new post' do
        expect {
          post :create, params: valid_params
        }.to change(Post, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'associates post with current user' do
        post :create, params: valid_params
        created_post = Post.last
        expect(created_post.user).to eq(user)
      end

      it 'returns the created post' do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Test Post')
        expect(json_response['body']).to eq('This is a test post body')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a post' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Post, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns error messages' do
        post :create, params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
      end
    end

    context 'with title too long' do
      let(:long_title_params) do
        {
          post: {
            title: 'a' * 101, # Exceeds 100 character limit
            body: 'Valid body'
          }
        }
      end

      it 'returns validation error' do
        post :create, params: long_title_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with body too long' do
      let(:long_body_params) do
        {
          post: {
            title: 'Valid title',
            body: 'a' * 1001 # Exceeds 1000 character limit
          }
        }
      end

      it 'returns validation error' do
        post :create, params: long_body_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: user_post.id,
        post: {
          title: 'Updated Title',
          body: 'Updated body content'
        }
      }
    end

    let(:invalid_update_params) do
      {
        id: user_post.id,
        post: {
          title: '',
          body: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'updates the post' do
        patch :update, params: update_params
        user_post.reload
        expect(user_post.title).to eq('Updated Title')
        expect(user_post.body).to eq('Updated body content')
      end

      it 'returns ok status' do
        patch :update, params: update_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated post' do
        patch :update, params: update_params
        json_response = JSON.parse(response.body)
        expect(json_response['title']).to eq('Updated Title')
        expect(json_response['body']).to eq('Updated body content')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the post' do
        original_title = user_post.title
        patch :update, params: invalid_update_params
        user_post.reload
        expect(user_post.title).to eq(original_title)
      end

      it 'returns unprocessable entity status' do
        patch :update, params: invalid_update_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when updating another user\'s post' do
      let(:other_post_params) do
        {
          id: other_post.id,
          post: {
            title: 'Hacked Title'
          }
        }
      end

      it 'returns forbidden status' do
        patch :update, params: other_post_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with non-existent post' do
      it 'returns not found status' do
        patch :update, params: { id: 99999, post: { title: 'Test' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user_post) { create(:post, user: user) }

    it 'soft deletes the post' do
      delete :destroy, params: { id: user_post.id }
      user_post.reload
      expect(user_post.deleted_at).to be_present
    end

    it 'returns no content status' do
      delete :destroy, params: { id: user_post.id }
      expect(response).to have_http_status(:no_content)
    end

    it 'does not actually delete the post from database' do
      initial_count = Post.count
      delete :destroy, params: { id: user_post.id }
      expect(Post.count).to eq(initial_count)
    end

    context 'when deleting another user\'s post' do
      it 'returns forbidden status' do
        delete :destroy, params: { id: other_post.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with non-existent post' do
      it 'returns not found status' do
        delete :destroy, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'authentication' do
    before do
      allow(controller).to receive(:authenticate_user!).and_call_original
    end

    it 'requires authentication for all actions' do
      expect(controller).to receive(:authenticate_user!).exactly(5).times

      get :index
      get :show, params: { id: user_post.id }
      post :create, params: { post: { title: 'Test', body: 'Test' } }
      patch :update, params: { id: user_post.id, post: { title: 'Updated' } }
      delete :destroy, params: { id: user_post.id }
    end
  end

  describe 'authorization' do
    context 'when user is not authorized' do
      before do
        allow(controller).to receive(:current_user).and_return(other_user)
      end

      it 'prevents updating other user\'s posts' do
        patch :update, params: { id: user_post.id, post: { title: 'Hacked' } }
        expect(response).to have_http_status(:forbidden)
      end

      it 'prevents deleting other user\'s posts' do
        delete :destroy, params: { id: user_post.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'parameter sanitization' do
    let(:malicious_params) do
      {
        post: {
          title: 'Test Title',
          body: 'Test Body',
          user_id: other_user.id, # Should be ignored
          deleted_at: Time.current, # Should be ignored
          view_count: 999 # Should be ignored
        }
      }
    end

    it 'only permits allowed parameters' do
      post :create, params: malicious_params
      created_post = Post.last
      expect(created_post.user_id).to eq(user.id) # Should use current_user
      expect(created_post.deleted_at).to be_nil
      expect(created_post.view_count).to eq(0) # Should use default
    end
  end
end
