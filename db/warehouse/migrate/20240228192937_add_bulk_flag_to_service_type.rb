class AddBulkFlagToServiceType < ActiveRecord::Migration[6.1]
  def change
    add_column :CustomServiceTypes, :bulk, :boolean, default: false, null: false, comment: 'whether to support bulk service assignment for this type in the hmis application'
  end
end
