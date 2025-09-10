require 'rails_helper'

RSpec.describe 'API::V1::Auth::Sessions', type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'POST /api/v1/auth/sign_in' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123'
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'wrongpassword'
        }
      }
    end

    context 'with valid credentials' do
      it 'returns 200 status' do
        post '/api/v1/auth/sign_in', params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns user data and token' do
        post '/api/v1/auth/sign_in', params: valid_params
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']).to include('id', 'email', 'username')
        expect(json_response['token']).to be_present
        expect(json_response['token']).to start_with('jwt_token_placeholder_')
      end

      it 'returns correct user data' do
        post '/api/v1/auth/sign_in', params: valid_params
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']['username']).to eq(user.username)
      end
    end

    context 'with invalid credentials' do
      it 'returns 401 status' do
        post '/api/v1/auth/sign_in', params: invalid_params
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns authentication error' do
        post '/api/v1/auth/sign_in', params: invalid_params
        json_response = JSON.parse(response.body)
        
        expect(json_response['error']).to include('code', 'message')
        expect(json_response['error']['code']).to eq('authentication_error')
        expect(json_response['error']['message']).to eq('Invalid email or password')
      end
    end

    context 'with non-existent user' do
      let(:non_existent_params) do
        {
          user: {
            email: 'nonexistent@example.com',
            password: 'password123'
          }
        }
      end

      it 'returns 401 status' do
        post '/api/v1/auth/sign_in', params: non_existent_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/auth/sign_out' do
    let(:token) { "jwt_token_placeholder_#{user.id}" }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with valid token' do
      it 'returns 204 status' do
        delete '/api/v1/auth/sign_out', headers: headers
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'without token' do
      it 'returns 401 status' do
        delete '/api/v1/auth/sign_out'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/auth/me' do
    let(:token) { "jwt_token_placeholder_#{user.id}" }
    let(:headers) { { 'Authorization' => "Bearer #{token}" } }

    context 'with valid token' do
      it 'returns 200 status' do
        get '/api/v1/auth/me', headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'returns current user data' do
        get '/api/v1/auth/me', headers: headers
        json_response = JSON.parse(response.body)
        
        expect(json_response['data']).to include('id', 'email', 'username')
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']['username']).to eq(user.username)
      end
    end

    context 'without token' do
      it 'returns 401 status' do
        get '/api/v1/auth/me'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid token' do
      let(:invalid_headers) { { 'Authorization' => 'Bearer invalid_token' } }

      it 'returns 401 status' do
        get '/api/v1/auth/me', headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
