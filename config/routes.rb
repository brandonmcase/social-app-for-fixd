Rails.application.routes.draw do
  get "/up", to: proc { [200, { "Content-Type" => "application/json" },
                        [ { status: "ok" }.to_json ]] }

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # This line creates the Devise mapping for :user (REQUIRED)
      devise_for :users,
                 path: "auth",
                 defaults: { format: :json },
                 skip: [:passwords, :confirmations],
                 controllers: {
                   sessions:      "api/v1/auth/sessions",
                   registrations: "api/v1/auth/registrations"
                 }

      # These routes must be INSIDE devise_scope(:user)
      devise_scope :user do
        post   "auth/register", to: "auth/registrations#create"
        post   "auth/sign_in",  to: "auth/sessions#create"
        delete "auth/sign_out", to: "auth/sessions#destroy"
        get    "auth/me",       to: "auth/sessions#me"
      end
    end
  end
end
