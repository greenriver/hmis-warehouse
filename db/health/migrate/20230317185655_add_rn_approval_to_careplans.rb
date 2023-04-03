class AddRnApprovalToCareplans < ActiveRecord::Migration[6.1]
  def change
    add_column :careplans, :rn_approval, :boolean
    add_reference :careplans, :approving_rn
    add_column :careplans, :rn_approved_on, :date
  end
end
