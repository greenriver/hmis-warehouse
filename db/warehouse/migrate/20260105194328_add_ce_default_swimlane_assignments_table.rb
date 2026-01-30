# frozen_string_literal: true

class AddCeDefaultSwimlaneAssignmentsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :ce_default_swimlane_assignments do |t|
      t.references :user, null: false, index: true
      t.references :swimlane, null: false, foreign_key: { to_table: :wfd_swimlanes }
      t.references :owner, polymorphic: true, null: false
      t.timestamp :deleted_at

      t.timestamps
    end
  end
end
