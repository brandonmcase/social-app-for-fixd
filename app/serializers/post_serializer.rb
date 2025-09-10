class PostSerializer
  def initialize(post)
    @post = post
  end

  def as_json
    @post.as_json(
      only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
      methods: [ :username ]
    )
  end
end
