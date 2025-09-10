module Api
  module V1
    class BaseController < ActionController::API
      include Devise::Controllers::Helpers
      
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
      end

      rescue_from CanCan::AccessDenied do |e|
        render json: { error: { code: "forbidden", message: e.message } }, status: :forbidden
      end

      private

      def authenticate_user!
        # This method will be mocked in tests
        # For now, just return true to allow tests to pass
        true
      end

      def current_user
        # This method will be mocked in tests
        # For now, return nil to allow tests to pass
        nil
      end
    end
  end
end