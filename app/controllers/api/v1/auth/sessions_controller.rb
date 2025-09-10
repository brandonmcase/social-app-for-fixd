module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        respond_to :json
        before_action :authenticate_user!, only: [:me]

        def create
          user = User.find_by(email: sign_in_params[:email])
          
          if user && user.valid_password?(sign_in_params[:password])
            render json: { 
              data: user.slice(:id, :email, :username),
              token: generate_jwt_token(user)
            }, status: :ok
          else
            render json: { 
              error: { 
                code: "authentication_error", 
                message: "Invalid email or password" 
              } 
            }, status: :unauthorized
          end
        end

        def destroy
          # Extract token from Authorization header
          token = extract_token_from_header
          
          if token && token.start_with?('jwt_token_placeholder_')
            # For our placeholder tokens, we could add them to a denylist
            # For now, we'll just return success
            head :no_content
          else
            # Handle real JWT tokens if they exist
            head :no_content
          end
        end

        def me
          render json: { data: current_user.slice(:id, :email, :username) }, status: :ok
        end

        private

        def sign_in_params
          params.require(:user).permit(:email, :password)
        end

        def generate_jwt_token(user)
          # This would typically use the JWT gem to generate a token
          # For now, we'll return a placeholder
          "jwt_token_placeholder_#{user.id}"
        end

        def authenticate_user!
          token = extract_token_from_header
          return render_unauthorized unless token
          
          user_id = extract_user_id_from_token(token)
          return render_unauthorized unless user_id
          
          @current_user = User.find_by(id: user_id)
          return render_unauthorized unless @current_user
        end

        def current_user
          @current_user
        end

        def extract_token_from_header
          auth_header = request.headers['Authorization']
          return nil unless auth_header&.start_with?('Bearer ')
          
          auth_header.split(' ').last
        end

        def extract_user_id_from_token(token)
          # For our placeholder token, extract the user ID
          return nil unless token&.start_with?('jwt_token_placeholder_')
          
          token.split('_').last.to_i
        end

        def render_unauthorized
          render json: { error: { code: "unauthorized", message: "Not authenticated" } }, status: :unauthorized
        end
      end
    end
  end
end
