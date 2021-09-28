class AddMemberByProcedureIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :claims_reporting_medical_claims, [:member_id, :procedure_code], name: 'med_claim_member_procedure_index'
  end
end
