class EnforceUniqUniverseMemberships < ActiveRecord::Migration[5.2]
  def up
    # Remove old indexes if they exist
    if index_exists? :hud_report_universe_members, [:report_cell_id]
      remove_index :hud_report_universe_members, column: [:report_cell_id]
    end

    if index_exists? :hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type]
      remove_index :hud_report_universe_members, column: [:report_cell_id, :universe_membership_id, :universe_membership_type]
    end

    add_index :hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type],
      unique: true,
      name: 'uniq_hud_report_universe_members',
      where: 'deleted_at IS NULL'
  end

  def down
    if index_exists? :hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type]
      remove_index :hud_report_universe_members, name: :uniq_hud_report_universe_members
    end
  end
end
