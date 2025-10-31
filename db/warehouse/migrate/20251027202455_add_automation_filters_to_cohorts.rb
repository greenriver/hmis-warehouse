# frozen_string_literal: true

class AddAutomationFiltersToCohorts < ActiveRecord::Migration[7.1]
  def change
    # use names that won't conflict with Cohort.available_columns
    add_column :cohorts, :automation_sub_population, :string
    add_column :cohorts, :automation_hoh_only, :boolean, default: false
  end
end
