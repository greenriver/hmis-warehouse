class ReindexServiceHistoryIndividual < ActiveRecord::Migration
  def change
    add_index GrdaWarehouse::ServiceHistory.table_name, [:date, :record_type, :presented_as_individual], name: :index_sh_date_r_type_indiv
  end
end
