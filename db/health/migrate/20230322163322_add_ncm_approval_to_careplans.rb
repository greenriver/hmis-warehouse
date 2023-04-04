class AddNcmApprovalToCareplans < ActiveRecord::Migration[6.1]
  def change
    add_column :careplans, :ncm_approval, :boolean
    add_reference :careplans, :approving_ncm
    add_column :careplans, :ncm_approved_on, :date
  end
end
