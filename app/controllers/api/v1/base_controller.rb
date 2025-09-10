module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
      end

      rescue_from CanCan::AccessDenied do |e|
        render json: { error: { code: "forbidden", message: e.message } }, status: :forbidden
      end
    end
  end
end