class SetLgbtqDataAndRemoveOldColumn < ActiveRecord::Migration
  def up
    GrdaWarehouse::CohortClient.where(lgbtq_boolean: true).update_all(lgbtq: 'Yes')
    remove_column :cohort_clients, :lgbtq_boolean, :boolean
  end
end
