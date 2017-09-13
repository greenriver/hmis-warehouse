class AddPresentedAsIndividualToSh < ActiveRecord::Migration
  def change
    add_column :warehouse_client_service_history, :presented_as_individual, :boolean
  end
end
