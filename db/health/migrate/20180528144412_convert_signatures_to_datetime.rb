class ConvertSignaturesToDatetime < ActiveRecord::Migration
  def up
    change_column :careplans, :patient_signed_on, :datetime
    change_column :careplans, :provider_signed_on, :datetime
  end
  def down
    change_column :careplans, :patient_signed_on, :date
    change_column :careplans, :provider_signed_on, :date
  end
end
