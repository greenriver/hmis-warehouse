class UniqUniverseMemberships < ActiveRecord::Migration[5.2]
  def change
    if index_exists? :hud_report_universe_members, [:report_cell_id]
      remove_index :hud_report_universe_members, column: [:report_cell_id]
    end
    add_index :hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type],
      unique: true,
      name: 'uniq_hud_report_universe_members'
  end
end
