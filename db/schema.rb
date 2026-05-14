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

ActiveRecord::Schema[7.1].define(version: 2026_05_14_010000) do
  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.string "author"
    t.text "description"
    t.integer "price", default: 0, null: false
    t.string "status", default: "listed", null: false
    t.string "condition"
    t.string "isbn"
    t.string "image_url"
    t.integer "seller_id", null: false
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_books_on_category_id"
    t.index ["seller_id"], name: "index_books_on_seller_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_favorites_on_book_id"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "message", null: false
    t.string "notification_type"
    t.integer "target_id"
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "book_id", null: false
    t.integer "buyer_id", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_price", default: 0
    t.integer "shipping_fee", default: 0
    t.integer "tax", default: 0
    t.string "payment_method"
    t.datetime "paid_at"
    t.datetime "shipped_at"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_orders_on_book_id"
    t.index ["buyer_id"], name: "index_orders_on_buyer_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "reviewer_id", null: false
    t.integer "target_user_id", null: false
    t.integer "rating", default: 3, null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_reviews_on_order_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["target_user_id"], name: "index_reviews_on_target_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "address"
    t.string "phone"
    t.integer "point", default: 0
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
