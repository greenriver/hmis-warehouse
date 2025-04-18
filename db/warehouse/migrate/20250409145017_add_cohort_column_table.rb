# frozen_string_literal: true

class AddCohortColumnTable < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_columns do |t|
      t.string :class_name, unique: true
      t.boolean :active, default: true
    end
  end
end
