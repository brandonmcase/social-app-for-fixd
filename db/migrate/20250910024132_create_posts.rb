class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false, limit: 100
      t.string :body, null: false, limit: 1000
      t.references :user, null: false, foreign_key: true
      t.datetime :deleted_at
      t.integer :view_count, null: false, default: 0

      t.jsonb :metadata, :jsonb, default: {}, null: false
      t.decimal :average_rating, precision: 3, scale: 2, default: 0.0
      t.integer :rating_count, default: 0


      t.timestamps
    end
    # Index for timeline ordering (most common query)
    add_index :posts, :created_at, name: 'index_posts_on_created_at_desc'

    # Composite index for filtered timeline queries (rating + date)
    add_index :posts, [ :average_rating, :created_at ], name: 'index_posts_on_rating_and_created_at'

    # Index for soft deletion queries
    add_index :posts, [ :deleted_at, :created_at ], name: 'index_posts_on_deleted_at_and_created_at'

    # Index for user posts with ordering
    add_index :posts, [ :user_id, :created_at ], name: 'index_posts_on_user_id_and_created_at'

    # Add specific indexes for common metadata queries
    add_index :posts, "(metadata->>'category')", name: 'index_posts_on_metadata_category'
    add_index :posts, "(metadata->>'tags')", name: 'index_posts_on_metadata_tags'
    add_index :posts, "(metadata->>'source')", name: 'index_posts_on_metadata_source'
    add_index :posts, "(metadata->>'language')", name: 'index_posts_on_metadata_language'

    # Add index for metadata existence checks
    add_index :posts, :metadata, using: :gin,
              where: "metadata ? 'featured'",
              name: 'index_posts_on_featured_metadata'
  end
end
