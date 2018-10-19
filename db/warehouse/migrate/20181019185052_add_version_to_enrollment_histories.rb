class AddVersionToEnrollmentHistories < ActiveRecord::Migration
  def change
    add_column :enrollment_change_histories, :version, :integer, null: false, default: 1
    add_column :enrollment_change_histories, :days_homeless, :integer
  end
end
