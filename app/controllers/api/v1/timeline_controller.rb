module Api
  module V1
    class TimelineController < BaseController
      # GET /api/v1/timeline
      def index
        posts = Post.active
                    .includes(:user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(params[:per_page] || 20)

        # Filter by minimum average rating if provided
        if params[:min_rating].present?
          min_rating = params[:min_rating].to_f
          posts = posts.where("average_rating >= ?", min_rating)
        end

        render json: posts.as_json(
          only: [:id, :title, :body, :view_count, :average_rating, :rating_count, :created_at],
          methods: [:username],
          include: {
            user: {
              only: [:id, :username]
            }
          }
        )
      end
    end
  end
end
