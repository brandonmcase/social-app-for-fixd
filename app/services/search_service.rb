class SearchService
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE     = 100
  CACHE_TTL        = 60.seconds

  def self.fetch(q:, page:, per_page:, min_rating:)
    new(q:, page:, per_page:, min_rating:).fetch
  end

  def initialize(q:, page:, per_page:, min_rating:)
    @q_raw      = q.to_s
    @q          = @q_raw.strip
    @page       = [ page.to_i, 1 ].max
    @per_page   = [ [ per_page.to_i.nonzero? || DEFAULT_PER_PAGE, 1 ].max, MAX_PER_PAGE ].min
    @min_rating = min_rating&.to_f
  end

  def fetch
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      scope = Post.active
      scope = scope.where("avg_rating >= ?", @min_rating) if @min_rating.present?

      # Full-text search using weighted tsvector + ranking
      posts = scope
                .fts(@q)         # WHERE search_vector @@ websearch_to_tsquery(...)
                .ranked(@q)      # SELECT ts_rank_cd(...) AS rank ORDER BY rank DESC
                .includes(:user) # avoid N+1 on author
                .page(@page).per(@per_page)

      {
        data: posts.map { |p| serialize_post(p).merge(rank: p.try(:rank)) },
        meta: {
          q: @q,
          page: posts.current_page,
          per_page: posts.limit_value,
          total_pages: posts.total_pages,
          total_count: posts.total_count,
          min_rating: @min_rating
        }
      }
    end
  end

  private

  def cache_key
    # Hash the query to keep keys short/safe
    digest = Digest::SHA1.hexdigest(@q)
    [
      "search:v1",
      "q:#{digest}",
      "mr:#{@min_rating || 'any'}",
      "p:#{@page}",
      "pp:#{@per_page}"
    ].join(":")
  end

  def serialize_post(p)
    {
      id: p.id,
      title: p.title,
      body: p.body,
      created_at: p.created_at,
      view_count: p.view_count,
      avg_rating: p.avg_rating.to_f,
      ratings_count: p.ratings_count,
      author: {
        id: p.user_id,
        username: p.user.username
      }
    }
  end
end
