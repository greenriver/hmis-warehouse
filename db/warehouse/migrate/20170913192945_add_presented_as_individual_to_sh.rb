class AddPresentedAsIndividualToSh < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_client_service_history, :presented_as_individual, :boolean
  end
end
