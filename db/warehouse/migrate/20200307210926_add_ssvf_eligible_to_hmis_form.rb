class AddSsvfEligibleToHmisForm < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_forms, :ssvf_eligible, :boolean, default: false
  end
end
