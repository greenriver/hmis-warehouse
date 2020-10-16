class AddColumnsForEnrollmentDisenrollmentFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :cps, :cp_name_official, :string

    add_column :accountable_care_organizations, :e_d_receiver_text, :string
    add_column :accountable_care_organizations, :e_d_file_prefix, :string
  end
end
