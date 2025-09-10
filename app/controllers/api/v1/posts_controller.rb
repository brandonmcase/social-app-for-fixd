module Api
  module V1
    class PostsController < BaseController
      before_action :authenticate_user!
      before_action :set_post, only: [:show, :update, :destroy]

      # GET /api/v1/posts
      def index
        posts = Post.active
                    .includes(:user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(params[:per_page] || 20)

        render json: posts.as_json(
          only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
          methods: [ :username ]
        )
      end

      # GET /api/v1/posts/:id
      def show
        @post.increment!(:view_count)
        render json: @post.as_json(
          only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
          methods: [ :username ]
        )
      end

      # POST /api/v1/posts
      def create
        post = current_user.posts.build(post_params)
        if post.save
          # Invalidate timeline cache when new post is created
          TimelineCacheService.invalidate_user_cache(current_user.id)
          render json: post, status: :created
        else
          render json: { error: post.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/posts/:id
      def update
        # Check if user owns the post
        unless @post.user == current_user
          return render json: { error: { code: "not_found", message: "Post not found" } }, status: :not_found
        end

        if @post.update(post_params)
          # Invalidate timeline cache when post is updated
          TimelineCacheService.invalidate_user_cache(current_user.id)
          render json: @post
        else
          render json: { error: @post.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/posts/:id
      def destroy
        # Check if user owns the post
        unless @post.user == current_user
          return render json: { error: { code: "not_found", message: "Post not found" } }, status: :not_found
        end

        @post.update(deleted_at: Time.current)
        # Invalidate timeline cache when post is deleted
        TimelineCacheService.invalidate_user_cache(current_user.id)
        render_no_content
      end

      private

      def set_post
        @post = Post.active.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "not_found", message: "Post not found" } }, status: :not_found
      end

      def post_params
        params.require(:post).permit(:title, :body)
      end
    end
  end
end
