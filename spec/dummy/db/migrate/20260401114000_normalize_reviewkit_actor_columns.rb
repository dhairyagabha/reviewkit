# frozen_string_literal: true

class NormalizeReviewkitActorColumns < ActiveRecord::Migration[8.1]
  def up
    normalize_polymorphic_actor(:reviewkit_reviews, :creator, legacy_column: :creator_gid)
    normalize_polymorphic_actor(:reviewkit_review_threads, :resolved_by, legacy_column: :resolved_by_gid)
    normalize_polymorphic_actor(:reviewkit_comments, :author, legacy_column: :author_gid)
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "This migration normalizes dummy app actor columns for tests."
  end

  private

  def normalize_polymorphic_actor(table_name, association_name, legacy_column:)
    unless column_exists?(table_name, :"#{association_name}_id")
      add_reference table_name, association_name, polymorphic: true, null: true
    end

    remove_column table_name, legacy_column, :string if column_exists?(table_name, legacy_column)
  end
end
