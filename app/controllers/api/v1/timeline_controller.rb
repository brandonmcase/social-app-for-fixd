module Api
  module V1
    class TimelineController < BaseController
      # GET /api/v1/timeline
      def index
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 20
        min_rating = params[:min_rating]&.to_f

        # Use caching service for better performance
        posts_data = TimelineCacheService.fetch_timeline(
          page: page,
          per_page: per_page,
          min_rating: min_rating
        )

        render json: posts_data
      end
    end
  end
end
