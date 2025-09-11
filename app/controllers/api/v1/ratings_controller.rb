module Api
  module V1
    class RatingsController < BaseController
      before_action :set_post
      before_action :set_rating, only: [ :show, :update, :destroy ]

      # GET /api/v1/posts/:post_id/rating
      def show
        if @rating
          render json: @rating
        else
          render json: { error: "No rating found" }, status: :not_found
        end
      end

      # POST /api/v1/posts/:post_id/rating
      def create
        DistributedLockService.with_rating_lock(@post.id, current_user.id) do
          ActiveRecord::Base.transaction do
            @rating = @post.ratings.build(rating_params.merge(user: current_user))

            if @rating.save
              render json: @rating, status: :created
            else
              render json: { error: @rating.errors.full_messages }, status: :unprocessable_content
              raise ActiveRecord::Rollback
            end
          end
        end
      rescue DistributedLockService::LockTimeout
        render json: { error: { code: "timeout", message: "Request timed out. Please try again." } }, status: :request_timeout
      rescue ActionController::ParameterMissing
        render json: { error: [ "Rating parameter is required" ] }, status: :unprocessable_content
      end

      # PATCH/PUT /api/v1/posts/:post_id/rating
      def update
        if @rating.nil?
          render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
        else
          DistributedLockService.with_rating_lock(@post.id, current_user.id) do
            ActiveRecord::Base.transaction do
              if @rating.update(rating_params)
                render json: @rating
              else
                render json: { error: @rating.errors.full_messages }, status: :unprocessable_content
                raise ActiveRecord::Rollback
              end
            end
          end
        end
      rescue DistributedLockService::LockTimeout
        render json: { error: { code: "timeout", message: "Request timed out. Please try again." } }, status: :request_timeout
      end

      # DELETE /api/v1/posts/:post_id/rating
      def destroy
        if @rating.nil?
          render json: { error: { code: "not_found", message: "Not found" } }, status: :not_found
        else
          DistributedLockService.with_rating_lock(@post.id, current_user.id) do
            ActiveRecord::Base.transaction do
              @rating.destroy
              head :no_content
            end
          end
        end
      rescue DistributedLockService::LockTimeout
        render json: { error: { code: "timeout", message: "Request timed out. Please try again." } }, status: :request_timeout
      end

      private

      def set_post
        @post = Post.active.find(params[:post_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "not_found", message: "Post not found" } }, status: :not_found
      end

      def set_rating
        @rating = @post.ratings.find_by(user: current_user)
      end

      def rating_params
        params.require(:rating).permit(:rating)
      end
    end
  end
end
