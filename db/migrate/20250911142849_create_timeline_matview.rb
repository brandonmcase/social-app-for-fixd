class CreateTimelineMatview < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW timeline_mv AS
      SELECT
        p.id               AS post_id,
        p.user_id,
        p.title,
        p.body,
        p.created_at,
        p.view_count,
        p.average_rating,
        p.rating_count
      FROM posts p
      WHERE p.deleted_at IS NULL;
    SQL

    # Unique index required for REFRESH CONCURRENTLY
    add_index :timeline_mv, :post_id, unique: true, name: "index_timeline_mv_on_post_id"
    add_index :timeline_mv, :created_at
    add_index :timeline_mv, :average_rating
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS timeline_mv;"
  end
end
