# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_01_06_133022) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "registering_spotify_users", force: :cascade do |t|
    t.string "broadcaster_username"
    t.string "identifier"
    t.bigint "spotify_app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_app_id"], name: "index_registering_spotify_users_on_spotify_app_id"
  end

  create_table "spotify_apps", force: :cascade do |t|
    t.string "name"
    t.string "client_identifier"
    t.string "client_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spotify_users", force: :cascade do |t|
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.bigint "spotify_user_id"
    t.string "song_name"
    t.string "song_uri"
    t.string "millisecond_progress_into_song"
    t.boolean "is_listening", default: false
    t.string "listen_along_token"
    t.string "last_song_uri"
    t.string "display_name"
    t.string "avatar_url"
    t.string "song_album_cover_url"
    t.string "song_artists", default: [], array: true
    t.boolean "maybe_intentionally_paused", default: false, null: false
    t.bigint "spotify_app_id"
    t.index ["spotify_app_id"], name: "index_spotify_users_on_spotify_app_id"
    t.index ["spotify_user_id"], name: "index_spotify_users_on_spotify_user_id"
  end

  add_foreign_key "registering_spotify_users", "spotify_apps"
  add_foreign_key "spotify_users", "spotify_apps"
  add_foreign_key "spotify_users", "spotify_users"
end
