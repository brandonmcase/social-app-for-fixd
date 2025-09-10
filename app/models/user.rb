class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable

  has_many :posts, dependent: :destroy

  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { maximum: 50 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/ }
end
