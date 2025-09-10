class Ability
  include CanCan::Ability

  def initialize(user)
    # Guest users can only read posts
    can :read, Post

    return unless user.present?

    # Authenticated users can create posts
    can :create, Post

    # Users can manage their own posts
    can :manage, Post, user: user

    # Users can read all posts
    can :read, Post, deleted_at: nil

    # Ratings: authorizations tied to the user/post
    can [:show, :create], Rating
    can [:update, :destroy], Rating, user_id: user.id

  end
end