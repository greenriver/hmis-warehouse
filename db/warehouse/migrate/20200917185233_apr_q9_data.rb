class AprQ9Data < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :date_of_engagement, :date
    add_column :hud_report_living_situations, :living_situation, :integer
  end
end
