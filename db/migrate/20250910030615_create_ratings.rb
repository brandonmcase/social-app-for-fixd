class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :rating, null: false

      t.timestamps
    end

    # Ensure a user can only rate a post once
    add_index :ratings, [ :user_id, :post_id ], unique: true
    # Add check constraint for rating range (1-5)
    add_check_constraint :ratings, "rating >= 1 AND rating <= 5", name: "rating_range_check"

    # Index for rating queries by post
    add_index :ratings, [ :post_id, :created_at ], name: 'index_ratings_on_post_id_and_created_at'

    # Index for user rating queries
    add_index :ratings, [ :user_id, :created_at ], name: 'index_ratings_on_user_id_and_created_at'
  end
end
