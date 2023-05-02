class AdditionalSystemEnrollmentColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :system_pathways_enrollments, :chronic_at_entry, :boolean
  end
end
