module Api
  module V1
    module Auth
      class SessionsController < BaseController
        include JwtAuthenticatable
        respond_to :json
        before_action :authenticate_user!, only: [ :me ]

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

          if token
            # For real JWT tokens, we could add them to a denylist
            # For now, we'll just return success (client should discard token)
            head :no_content
          else
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

        def authenticate_user!
          token = extract_token_from_header
          return render_unauthorized unless token

          payload = decode_jwt_token(token)
          return render_unauthorized unless payload

          @current_user = User.find_by(id: payload["user_id"])
          render_unauthorized unless @current_user
        end

        def current_user
          @current_user
        end

        def extract_token_from_header
          auth_header = request.headers["Authorization"]
          return nil unless auth_header&.start_with?("Bearer ")

          auth_header.split(" ").last
        end

        def render_unauthorized
          render json: { error: { code: "unauthorized", message: "Not authenticated" } }, status: :unauthorized
        end
      end
    end
  end
end
