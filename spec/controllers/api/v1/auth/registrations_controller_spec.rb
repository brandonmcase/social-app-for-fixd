require 'rails_helper'

RSpec.describe Api::V1::Auth::RegistrationsController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          email: 'invalid-email',
          username: '',
          password: '123',
          password_confirmation: 'different'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(User, :count).by(1)
      end

      it 'returns a 201 status code' do
        post :create, params: valid_params, format: :json
        expect(response).to have_http_status(:created)
      end

      it 'returns the user data' do
        post :create, params: valid_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['data']).to include(
          'email' => 'test@example.com',
          'username' => 'testuser'
        )
        expect(json_response['data']['id']).to be_present
      end

      it 'does not include password in response' do
        post :create, params: valid_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['data']).not_to have_key('password')
        expect(json_response['data']).not_to have_key('encrypted_password')
      end

      it 'sets the correct content type' do
        post :create, params: valid_params, format: :json
        expect(response.content_type).to include('application/json')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(User, :count)
      end

      it 'returns a 422 status code' do
        post :create, params: invalid_params, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns validation errors' do
        post :create, params: invalid_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['error']).to include(
          'code' => 'validation_error',
          'message' => 'Invalid registration'
        )
        expect(json_response['error']['details']).to be_present
      end

      it 'includes specific validation errors' do
        post :create, params: invalid_params, format: :json
        json_response = JSON.parse(response.body)
        errors = json_response['error']['details']

        expect(errors['email']).to include('is invalid')
        expect(errors['username']).to include("can't be blank")
        expect(errors['password']).to include('is too short (minimum is 8 characters)')
        expect(errors['password_confirmation']).to include("doesn't match Password")
      end
    end

    context 'with duplicate email' do
      before do
        create(:user, email: 'existing@example.com')
      end

      let(:duplicate_email_params) do
        {
          user: {
            email: 'existing@example.com',
            username: 'newuser',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: duplicate_email_params, format: :json
        }.not_to change(User, :count)
      end

      it 'returns a 422 status code' do
        post :create, params: duplicate_email_params, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns email already taken error' do
        post :create, params: duplicate_email_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['error']['details']['email']).to include('has already been taken')
      end
    end

    context 'with duplicate username' do
      before do
        create(:user, username: 'existinguser')
      end

      let(:duplicate_username_params) do
        {
          user: {
            email: 'new@example.com',
            username: 'existinguser',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: duplicate_username_params, format: :json
        }.not_to change(User, :count)
      end

      it 'returns a 422 status code' do
        post :create, params: duplicate_username_params, format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns username already taken error' do
        post :create, params: duplicate_username_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['error']['details']['username']).to include('has already been taken')
      end
    end

    context 'with missing user parameter' do
      it 'raises a parameter missing error' do
        post :create, params: {}, format: :json
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('missing_parameter')
      end
    end

    context 'with malformed JSON' do
      it 'handles malformed JSON gracefully' do
        request.env['CONTENT_TYPE'] = 'application/json'
        request.env['RAW_POST_DATA'] = '{"user":{"email":"test@example.com"'

        post :create, format: :json
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']['code']).to eq('missing_parameter')
      end
    end

    context 'password encryption' do
      it 'encrypts the password before saving' do
        post :create, params: valid_params, format: :json

        user = User.last
        expect(user.encrypted_password).to be_present
        expect(user.encrypted_password).not_to eq('password123')
        expect(user.valid_password?('password123')).to be true
      end
    end

    context 'response format' do
      it 'responds with JSON format' do
        post :create, params: valid_params, format: :json
        expect(response.content_type).to include('application/json')
      end

      it 'includes proper headers' do
        post :create, params: valid_params, format: :json
        expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
        expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      end
    end
  end

  describe 'parameter sanitization' do
    let(:params_with_extra_fields) do
      {
        user: {
          email: 'test@example.com',
          username: 'testuser',
          password: 'password123',
          password_confirmation: 'password123',
          admin: true,
          role: 'admin',
          created_at: Time.current
        }
      }
    end

    it 'only permits allowed parameters' do
      post :create, params: params_with_extra_fields, format: :json

      user = User.last
      expect(user.email).to eq('test@example.com')
      expect(user.username).to eq('testuser')
      expect(user).not_to respond_to(:admin)
      expect(user).not_to respond_to(:role)
    end
  end
end
