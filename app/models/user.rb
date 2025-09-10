class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { maximum: 50 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/ }
end