class AddAuditActionsToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :enrollments, :audit_actions, :jsonb, default: {}
  end
end
