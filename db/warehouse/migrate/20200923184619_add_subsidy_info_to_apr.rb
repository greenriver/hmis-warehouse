class AddSubsidyInfoToApr < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_apr_clients, :subsidy_information, :integer
  end
end
