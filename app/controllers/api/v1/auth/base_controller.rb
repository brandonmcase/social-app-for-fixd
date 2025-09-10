module Api
  module V1
    module Auth
      class BaseController < ActionController::API
        include JsonResponder
        include Devise::Controllers::Helpers

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
      end
    end
  end
end
