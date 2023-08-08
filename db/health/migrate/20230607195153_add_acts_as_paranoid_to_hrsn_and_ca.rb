class AddActsAsParanoidToHrsnAndCa < ActiveRecord::Migration[6.1]
  def change
    add_column :thrive_assessments, :deleted_at, :datetime
    add_column :hrsn_screenings, :deleted_at, :datetime
    add_column :hca_assessments, :deleted_at, :datetime
    add_column :ca_assessments, :deleted_at, :datetime
  end
end
