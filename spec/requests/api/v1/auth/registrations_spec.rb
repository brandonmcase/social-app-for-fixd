require 'rails_helper'

RSpec.describe 'API::V1::Auth::Registrations', type: :request do
  describe 'POST /api/v1/auth/register' do
    let(:valid_user_params) do
      {
        user: {
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    let(:invalid_user_params) do
      {
        user: {
          email: 'invalid-email',
          username: '',
          password: '123',
          password_confirmation: '456'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post '/api/v1/auth/register', params: valid_user_params
        }.to change(User, :count).by(1)
      end

      it 'returns 201 status' do
        post '/api/v1/auth/register', params: valid_user_params
        expect(response).to have_http_status(:created)
      end

      it 'returns user data without password' do
        post '/api/v1/auth/register', params: valid_user_params
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']).to include('id', 'email', 'username')
        expect(json_response['data']).not_to include('password', 'encrypted_password')
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']['username']).to eq('testuser')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post '/api/v1/auth/register', params: invalid_user_params
        }.not_to change(User, :count)
      end

      it 'returns 422 status' do
        post '/api/v1/auth/register', params: invalid_user_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns validation errors' do
        post '/api/v1/auth/register', params: invalid_user_params
        json_response = JSON.parse(response.body)
        
        expect(json_response['error']).to include('code', 'message', 'details')
        expect(json_response['error']['code']).to eq('validation_error')
        expect(json_response['error']['details']).to be_present
      end
    end

    context 'with duplicate email' do
      before { create(:user, email: 'test@example.com') }

      it 'returns validation error' do
        post '/api/v1/auth/register', params: valid_user_params
        expect(response).to have_http_status(:unprocessable_content)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']['details']).to include('email' => ['has already been taken'])
      end
    end

    context 'with duplicate username' do
      before { create(:user, username: 'testuser') }

      it 'returns validation error' do
        post '/api/v1/auth/register', params: valid_user_params
        expect(response).to have_http_status(:unprocessable_content)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']['details']).to include('username' => ['has already been taken'])
      end
    end
  end
end
