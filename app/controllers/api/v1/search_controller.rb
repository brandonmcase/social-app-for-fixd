module Api
  module V1
    class SearchController < BaseController
      skip_before_action :authenticate_user!, only: [ :index ]

      # GET /api/v1/search?q=...&page=1&per_page=20
      def index
        q         = params[:q].to_s
        page      = params[:page]&.to_i || 1
        per_page  = params[:per_page]&.to_i || 20
        min_rating = params[:min_rating]&.to_f

        if q.strip.empty?
          return render_error(code: "bad_request", message: "Missing search query", status: :bad_request)
        end

        results = SearchService.fetch(
          q: q,
          page: page,
          per_page: per_page,
          min_rating: min_rating
        )

        render json: results
      end
    end
  end
end
