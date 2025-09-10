module Api
  module V1
    class PostsController < BaseController
      load_and_authorize_resource

      # GET /api/v1/posts
      def index
        posts = Post.active
                    .includes(:user)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(params[:per_page] || 20)

        render json: posts.as_json(
          only: [:id, :title, :body, :view_count, :average_rating, :rating_count, :created_at],
          methods: [:username]
        )
      end

      # GET /api/v1/posts/:id
      def show
        post = Post.active.find(params[:id])
        post.increment!(:view_count)
        render json: post.as_json(
          only: [:id, :title, :body, :view_count, :average_rating, :rating_count, :created_at],
          methods: [:username]
        )
      end

      # POST /api/v1/posts
      def create
        post = current_user.posts.build(post_params)
        if post.save
          render json: post, status: :created
        else
          render json: { error: post.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/posts/:id
      def update
        post = current_user.posts.find(params[:id])
        if post.update(post_params)
          render json: post
        else
          render json: { error: post.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/posts/:id
      def destroy
        post = current_user.posts.find(params[:id])
        post.update(deleted_at: Time.current)
        head :no_content
      end

      private

      def post_params
        params.require(:post).permit(:title, :body)
      end
    end
  end
end
