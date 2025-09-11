module Api
  module V1
    class PostsController < BaseController
      before_action :authenticate_user!
      before_action :set_post, only: [ :show, :update, :destroy ]

      # GET /api/v1/posts
      def index
        posts = Post.active
                    .filters(params)
                    .includes(:user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(params[:per_page] || 20)

        render json: posts.as_json(
          only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
          methods: [ :username, :metadata ]
        )
      end

      # GET /api/v1/posts/:id
      def show
        # Queue view count update asynchronously to avoid blocking the request
        # In test environment, this will be processed synchronously
        ViewCountUpdateJob.perform_later(@post.id, current_user&.id)

        render json: @post.as_json(
          only: [ :id, :title, :body, :view_count, :average_rating, :rating_count, :created_at ],
          methods: [ :username ]
        )
      end

      # POST /api/v1/posts
      def create
        post = current_user.posts.build(post_params)
        if post.save
          # Queue timeline cache invalidation asynchronously
          TimelineCacheWarmJob.perform_later(current_user.id)
          render json: post, status: :created
        else
          render json: { error: post.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/posts/:id
      def update
        # Check if user owns the post
        unless @post.user == current_user
          return render json: { error: { code: "forbidden", message: "Not authorized to update this post" } }, status: :forbidden
        end

        begin
          if @post.update(post_params)
            # Queue timeline cache invalidation asynchronously
            TimelineCacheWarmJob.perform_later(current_user.id)
            render json: @post
          else
            render json: { error: @post.errors.full_messages }, status: :unprocessable_content
          end
        rescue ActiveRecord::StaleObjectError
          render json: {
            error: {
              code: "conflict",
              message: "This post has been modified by another user. Please refresh and try again."
            }
          }, status: :conflict
        end
      end

      # DELETE /api/v1/posts/:id
      def destroy
        # Check if user owns the post
        unless @post.user == current_user
          return render json: { error: { code: "forbidden", message: "Not authorized to delete this post" } }, status: :forbidden
        end

        @post.update(deleted_at: Time.current)
        # Queue timeline cache invalidation asynchronously
        TimelineCacheWarmJob.perform_later(current_user.id)
        render_no_content
      end

      private

      def set_post
        @post = Post.active.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "not_found", message: "Post not found" } }, status: :not_found
      end

      def post_params
        params.require(:post).permit(:title, :body, metadata: {})
      end
    end
  end
end
