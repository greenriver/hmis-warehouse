class AddQuestionSevenFieldsToAprClients < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :move_in_date, :date
    add_column :hud_report_apr_clients, :household_type, :string
  end
end
