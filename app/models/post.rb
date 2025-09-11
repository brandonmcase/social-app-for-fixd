class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :body,  presence: true, length: { maximum: 1000 }

  after_commit :bust_search_cache, on: [ :create, :update, :destroy ]

  scope :active, -> { where(deleted_at: nil) }

  scope :fts, ->(q) {
    where("search_vector @@ websearch_to_tsquery('english', unaccent(?))", q)
  }

  # Basic/plain syntax as a fallback (no operators)
  scope :fts_plain, ->(q) {
    where("search_vector @@ plainto_tsquery('english', unaccent(?))", q)
  }

  # Ranked ordering helper (ts_rank_cd favors rare terms)
  scope :ranked, ->(q) {
    select("posts.*, ts_rank_cd(search_vector, websearch_to_tsquery('english', unaccent(#{ActiveRecord::Base.connection.quote(q)}))) AS rank")
      .order(Arel.sql("rank DESC, posts.created_at DESC"))
  }

  # Enable optimistic locking
  self.locking_column = :lock_version

  def username
    user.username
  end

  private

  def bust_search_cache
    Rails.cache.delete_matched("search:v1:*")
  end
end
