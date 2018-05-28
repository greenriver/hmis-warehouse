class AddCasReadinessFieldsToClient < ActiveRecord::Migration
  def change
    add_column :Client, :rrh_assessment_score, :integer
    add_column :Client, :ssvf_eligible, :boolean, default: false, null: false
    add_column :Client, :rrh_desired, :boolean, default: false, null: false
    add_column :Client, :youth_rrh_desired, :boolean, default: false, null: false
    add_column :Client, :rrh_assessment_contact_info, :string
    add_column :Client, :rrh_assessment_collected_at, :datetime

  end
end
