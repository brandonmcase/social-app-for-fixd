class Post < ApplicationRecord
  store_accessor :metadata, :language, :client

  # Enable optimistic locking
  self.locking_column = :lock_version

  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :body,  presence: true, length: { maximum: 1000 }

  validate :metadata_is_object

  after_commit :bust_search_cache, on: [ :create, :update, :destroy ]

  scope :active, -> { where(deleted_at: nil) }

  scope :with_language,  ->(code) { where("metadata ->> 'language' = ?", code) }
  scope :with_tag,   ->(tag)  { where("metadata -> 'tags' ? :t", t: tag) }
  scope :featured,   ->       { where("(metadata->'featured')::boolean = true") }
  scope :min_score,  ->(x)    { where("(metadata->>'score')::decimal >= ?", x) }
  scope :min_score,  ->(x)    { where("(metadata->>'score')::decimal >= ?", x) }




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

  def username
    user.username
  end

  def metadata_is_object
    errors.add(:metadata, "must be a JSON object") unless metadata.is_a?(Hash)
  end

  def self.filters(params)
    posts = all
    posts = posts.with_language(params[:language]) if params[:language].present?
    posts = posts.with_tag(params[:tag])           if params[:tag].present?
    posts = posts.featured                         if ActiveModel::Type::Boolean.new.cast(params[:featured])
    posts = posts.min_score(params[:min_score])    if params[:min_score].present?
    posts
  end

  private

  def bust_search_cache
    Rails.cache.delete_matched("search:v1:*")
  end
end
