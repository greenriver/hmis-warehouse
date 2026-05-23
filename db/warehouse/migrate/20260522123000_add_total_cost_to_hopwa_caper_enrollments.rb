# frozen_string_literal: true

class AddTotalCostToHopwaCaperEnrollments < ActiveRecord::Migration[7.1]
  def change
    add_column :hopwa_caper_enrollments, :total_project_cost, :integer
  end
end
