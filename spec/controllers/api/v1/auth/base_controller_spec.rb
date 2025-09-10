require 'rails_helper'

RSpec.describe Api::V1::Auth::BaseController, type: :controller do
  # Create a test controller to test the base controller functionality
  controller do
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

  before do
    routes.draw do
      get 'test_record_not_found' => 'api/v1/auth/base#test_record_not_found'
      get 'test_record_invalid' => 'api/v1/auth/base#test_record_invalid'
      get 'test_access_denied' => 'api/v1/auth/base#test_access_denied'
      get 'test_parameter_missing' => 'api/v1/auth/base#test_parameter_missing'
    end
  end

  describe 'error handling' do
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
