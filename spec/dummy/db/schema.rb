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

ActiveRecord::Schema[8.1].define(version: 2026_04_01_114000) do
  create_table "reviewers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_reviewers_on_email", unique: true
  end

  create_table "reviewkit_comments", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.json "metadata", default: {}, null: false
    t.integer "review_thread_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_reviewkit_comments_on_author"
    t.index ["review_thread_id"], name: "index_reviewkit_comments_on_review_thread_id"
  end

  create_table "reviewkit_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "diff_cache", default: {}, null: false
    t.string "language", default: "plaintext", null: false
    t.json "metadata", default: {}, null: false
    t.text "new_content"
    t.text "old_content"
    t.string "path", null: false
    t.integer "position", default: 0, null: false
    t.integer "review_id", null: false
    t.string "status", default: "modified", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id", "path"], name: "index_reviewkit_documents_on_review_id_and_path", unique: true
    t.index ["review_id", "position"], name: "index_reviewkit_documents_on_review_id_and_position"
    t.index ["review_id"], name: "index_reviewkit_documents_on_review_id"
    t.index ["status"], name: "index_reviewkit_documents_on_status"
  end

  create_table "reviewkit_review_threads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.string "line_code", null: false
    t.json "metadata", default: {}, null: false
    t.integer "new_line"
    t.integer "old_line"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.string "resolved_by_type"
    t.integer "review_id", null: false
    t.string "side", default: "new", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "line_code"], name: "index_reviewkit_review_threads_on_document_id_and_line_code"
    t.index ["document_id"], name: "index_reviewkit_review_threads_on_document_id"
    t.index ["resolved_by_type", "resolved_by_id"], name: "index_reviewkit_review_threads_on_resolved_by"
    t.index ["review_id"], name: "index_reviewkit_review_threads_on_review_id"
    t.index ["status"], name: "index_reviewkit_review_threads_on_status"
  end

  create_table "reviewkit_reviews", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "creator_id"
    t.string "creator_type"
    t.text "description"
    t.string "external_reference"
    t.json "metadata", default: {}, null: false
    t.string "review_type"
    t.integer "reviewable_id"
    t.string "reviewable_type"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_type", "creator_id"], name: "index_reviewkit_reviews_on_creator"
    t.index ["external_reference"], name: "index_reviewkit_reviews_on_external_reference"
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviewkit_reviews_on_reviewable"
    t.index ["status"], name: "index_reviewkit_reviews_on_status"
  end

  add_foreign_key "reviewkit_comments", "reviewkit_review_threads", column: "review_thread_id"
  add_foreign_key "reviewkit_documents", "reviewkit_reviews", column: "review_id"
  add_foreign_key "reviewkit_review_threads", "reviewkit_documents", column: "document_id"
  add_foreign_key "reviewkit_review_threads", "reviewkit_reviews", column: "review_id"
end
