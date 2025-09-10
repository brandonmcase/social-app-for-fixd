module Api
  module V1
    class BaseController < ActionController::API
      include JsonResponder
      include Devise::Controllers::Helpers

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

        user_id = extract_user_id_from_token(token)
        return render_unauthorized unless user_id

        @current_user = User.find_by(id: user_id)
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

      def extract_user_id_from_token(token)
        # Extract user ID from placeholder token format: jwt_token_placeholder_{user_id}
        return nil unless token&.start_with?("jwt_token_placeholder_")

        user_id_str = token.split("_").last
        user_id_str.to_i if user_id_str.match?(/\A\d+\z/)
      end

      def render_unauthorized
        super(message: "Invalid or missing token")
      end
    end
  end
end
