# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_10_030615) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.string "title", limit: 100, null: false
    t.string "body", limit: 1000, null: false
    t.bigint "user_id", null: false
    t.datetime "deleted_at"
    t.integer "view_count", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "jsonb", default: {}, null: false
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0"
    t.integer "rating_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((metadata ->> 'category'::text))", name: "index_posts_on_metadata_category"
    t.index "((metadata ->> 'language'::text))", name: "index_posts_on_metadata_language"
    t.index "((metadata ->> 'source'::text))", name: "index_posts_on_metadata_source"
    t.index "((metadata ->> 'tags'::text))", name: "index_posts_on_metadata_tags"
    t.index ["average_rating", "created_at"], name: "index_posts_on_rating_and_created_at"
    t.index ["created_at"], name: "index_posts_on_created_at_desc"
    t.index ["deleted_at", "created_at"], name: "index_posts_on_deleted_at_and_created_at"
    t.index ["metadata"], name: "index_posts_on_featured_metadata", where: "(metadata ? 'featured'::text)", using: :gin
    t.index ["user_id", "created_at"], name: "index_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.integer "rating", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "created_at"], name: "index_ratings_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_ratings_on_post_id"
    t.index ["user_id", "created_at"], name: "index_ratings_on_user_id_and_created_at"
    t.index ["user_id", "post_id"], name: "index_ratings_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "rating_range_check"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "posts", "users"
  add_foreign_key "ratings", "posts"
  add_foreign_key "ratings", "users"
end
