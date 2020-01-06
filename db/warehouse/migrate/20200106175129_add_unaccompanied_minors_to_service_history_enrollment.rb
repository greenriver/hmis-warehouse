class AddUnaccompaniedMinorsToServiceHistoryEnrollment < ActiveRecord::Migration[5.2]
  def change
    add_column :service_history_enrollments, :unaccompanied_minor, :boolean, default: false
  end
end
