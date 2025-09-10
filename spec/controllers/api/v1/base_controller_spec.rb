require 'rails_helper'

RSpec.describe Api::V1::BaseController, type: :controller do
  include JwtTokenHelper

  # Create a test controller to test the base controller functionality
  controller do
    def test_action
      render json: { data: 'success' }
    end

    def test_record_not_found
      raise ActiveRecord::RecordNotFound
    end

    def test_record_invalid
      user = User.new
      user.save!
    end

    def test_access_denied
      raise CanCan::AccessDenied.new("Not authorized")
    end

    def test_parameter_missing
      params.require(:missing_param)
    end
  end

  let(:user) { create(:user) }
  let(:token) { generate_jwt_token(user) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    routes.draw do
      get 'test_action' => 'api/v1/base#test_action'
      get 'test_record_not_found' => 'api/v1/base#test_record_not_found'
      get 'test_record_invalid' => 'api/v1/base#test_record_invalid'
      get 'test_access_denied' => 'api/v1/base#test_access_denied'
      get 'test_parameter_missing' => 'api/v1/base#test_parameter_missing'
    end
  end

  describe 'authentication' do
    context 'with valid token' do
      it 'allows access to protected actions' do
        request.headers.merge!(headers)
        get :test_action
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']).to eq('success')
      end
    end

    context 'without token' do
      it 'denies access' do
        get :test_action
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('unauthorized')
      end
    end

    context 'with invalid token format' do
      it 'denies access for invalid tokens' do
        invalid_headers = { 'Authorization' => 'Bearer invalid_token' }
        request.headers.merge!(invalid_headers)
        get :test_action
        expect(response).to have_http_status(:unauthorized)
      end

      it 'denies access for malformed JWT tokens' do
        invalid_headers = { 'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiJ9.invalid' }
        request.headers.merge!(invalid_headers)
        get :test_action
        expect(response).to have_http_status(:unauthorized)
      end

      it 'denies access for expired tokens' do
        expired_payload = {
          user_id: user.id,
          email: user.email,
          username: user.username,
          exp: 1.hour.ago.to_i, # Expired
          iat: 2.hours.ago.to_i
        }
        expired_token = JWT.encode(expired_payload, jwt_secret, 'HS256')
        invalid_headers = { 'Authorization' => "Bearer #{expired_token}" }
        request.headers.merge!(invalid_headers)
        get :test_action
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with non-existent user' do
      it 'denies access' do
        non_existent_payload = {
          user_id: 99999,
          email: 'nonexistent@example.com',
          username: 'nonexistent',
          exp: 24.hours.from_now.to_i,
          iat: Time.current.to_i
        }
        invalid_token = JWT.encode(non_existent_payload, jwt_secret, 'HS256')
        invalid_headers = { 'Authorization' => "Bearer #{invalid_token}" }
        request.headers.merge!(invalid_headers)
        get :test_action
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'error handling' do
    before { request.headers.merge!(headers) }

    it 'handles RecordNotFound errors' do
      get :test_record_not_found
      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['error']['code']).to eq('not_found')
    end

    it 'handles RecordInvalid errors' do
      get :test_record_invalid
      expect(response).to have_http_status(:unprocessable_content)
      json_response = JSON.parse(response.body)
      expect(json_response['error']['code']).to eq('validation_error')
    end

    it 'handles AccessDenied errors' do
      get :test_access_denied
      expect(response).to have_http_status(:forbidden)
      json_response = JSON.parse(response.body)
      expect(json_response['error']['code']).to eq('forbidden')
    end

    it 'handles ParameterMissing errors' do
      get :test_parameter_missing
      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['error']['code']).to eq('missing_parameter')
    end
  end
end
