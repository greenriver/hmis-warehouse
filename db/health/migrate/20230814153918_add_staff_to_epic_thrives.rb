# frozen_string_literal: true

class AddStaffToEpicThrives < ActiveRecord::Migration[6.1]
  def change
    add_column :epic_thrives, :staff, :string
  end
end
