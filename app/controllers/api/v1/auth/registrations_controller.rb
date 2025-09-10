module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        respond_to :json

        def create
          user = User.new(user_params)

          if user.save
            render json: { data: user.slice(:id, :email, :username) }, status: :created
          else
            render json: { error: { code: "validation_error", message: "Invalid registration", details: user.errors } },
                   status: :unprocessable_content
          end
        end

        private

        def user_params
          params.require(:user).permit(:email, :username, :password, :password_confirmation)
        end
      end
    end
  end
end
