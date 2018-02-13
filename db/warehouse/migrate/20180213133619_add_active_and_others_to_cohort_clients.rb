class AddActiveAndOthersToCohortClients < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :active, :boolean, default: true, null: false
    add_column :cohort_clients, :provider, :string
    add_column :cohort_clients, :next_step, :string
    add_column :cohort_clients, :housing_plan, :text
    add_column :cohort_clients, :document_ready_on, :date
  end
end
