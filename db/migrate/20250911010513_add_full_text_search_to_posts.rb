# db/migrate/XXXXXXXXXX_add_full_text_search_to_posts.rb
class AddFullTextSearchToPosts < ActiveRecord::Migration[8.0]
  def up
    enable_extension "unaccent" unless extension_enabled?("unaccent")

    # 1) Add the column (not generated)
    add_column :posts, :search_vector, :tsvector

    # 2) Create a trigger function to keep it in sync
    execute <<~SQL
      CREATE OR REPLACE FUNCTION posts_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', unaccent(coalesce(NEW.title, ''))), 'A') ||
          setweight(to_tsvector('english', unaccent(coalesce(NEW.body,  ''))), 'B');
        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL

    # 3) Add the trigger on INSERT/UPDATE of title/body
    execute <<~SQL
      CREATE TRIGGER trg_posts_search_vector_update
      BEFORE INSERT OR UPDATE OF title, body ON posts
      FOR EACH ROW EXECUTE FUNCTION posts_search_vector_update();
    SQL

    # 4) Backfill existing rows
    execute <<~SQL
      UPDATE posts
      SET search_vector =
        setweight(to_tsvector('english', unaccent(coalesce(title, ''))), 'A') ||
        setweight(to_tsvector('english', unaccent(coalesce(body,  ''))), 'B');
    SQL

    # 5) GIN index for fast @@ lookups
    add_index :posts, :search_vector, using: :gin
  end

  def down
    remove_index :posts, :search_vector
    execute "DROP TRIGGER IF EXISTS trg_posts_search_vector_update ON posts;"
    execute "DROP FUNCTION IF EXISTS posts_search_vector_update();"
    remove_column :posts, :search_vector
    # keep unaccent enabled (harmless); drop it if you really want:
    # disable_extension "unaccent" if extension_enabled?("unaccent")
  end
end
