# frozen_string_literal: true

class AddAutomationUpdatedAtToCohorts < ActiveRecord::Migration[7.1]
  def change
    add_column :cohorts, :automation_updated_at, :datetime
  end
end
