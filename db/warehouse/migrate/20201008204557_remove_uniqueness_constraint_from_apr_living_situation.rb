class RemoveUniquenessConstraintFromAprLivingSituation < ActiveRecord::Migration[5.2]
  def up
    remove_index :hud_report_apr_living_situations, name: 'index_hud_apr_client_liv_sit'
    add_index :hud_report_apr_living_situations, :hud_report_apr_client_id, name: 'index_hud_apr_client_liv_sit'
  end
end
