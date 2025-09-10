module Api
  module V1
    class BaseController < ActionController::API
      include JsonResponder
      include Devise::Controllers::Helpers
      include JwtAuthenticatable

      before_action :authenticate_user!

      # Standard error handling
      rescue_from ActiveRecord::RecordNotFound do
        render_not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_validation_error(e.record.errors, message: "Invalid record")
      end

      rescue_from CanCan::AccessDenied do |e|
        render_forbidden(e.message)
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error(
          code: "missing_parameter",
          message: "Required parameter missing: #{e.param}",
          status: :bad_request
        )
      end

      private

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
        super(message: "Invalid or missing token")
      end
    end
  end
end
