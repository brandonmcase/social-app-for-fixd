class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :body,  presence: true, length: { maximum: 1000 }

  scope :active, -> { where(deleted_at: nil) }

  def username
    user.username
  end
end