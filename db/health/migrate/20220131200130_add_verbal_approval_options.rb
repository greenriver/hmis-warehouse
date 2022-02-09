class AddVerbalApprovalOptions < ActiveRecord::Migration[5.2]
  def change
    add_column :participation_forms, :verbal_approval, :boolean, default: false
    add_column :release_forms, :verbal_approval, :boolean, default: false
  end
end
