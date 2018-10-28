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

ActiveRecord::Schema.define(version: 2018_10_28_010328) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coupons", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "available_from", null: false
    t.datetime "expired_at", null: false
    t.string "photo_url", null: false
    t.bigint "shop_id", null: false
    t.bigint "user_id", null: false
    t.float "insta_score", null: false
    t.boolean "is_used", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "comment", null: false
    t.string "tweet_url", null: false
    t.bigint "food_category_id"
    t.string "uuid", null: false
    t.index ["food_category_id"], name: "index_coupons_on_food_category_id"
    t.index ["shop_id"], name: "index_coupons_on_shop_id"
    t.index ["user_id"], name: "index_coupons_on_user_id"
  end

  create_table "food_categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "address", null: false
    t.float "latitude"
    t.float "longitude"
    t.integer "mean_coupon", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "twitter_name", null: false
    t.string "twitter_id", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "twitter_desc"
    t.string "access_secret"
    t.string "access_token"
    t.text "credentials"
    t.text "raw_info"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "coupons", "food_categories"
end
