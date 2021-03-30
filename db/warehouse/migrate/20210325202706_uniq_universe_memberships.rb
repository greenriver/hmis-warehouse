class UniqUniverseMemberships < ActiveRecord::Migration[5.2]
  def up
    cells_with_duplicates = {}.tap do |hash|
      HudReports::UniverseMember.
        group(:report_cell_id, :client_id).having('count(*) > 1').
        pluck(:report_cell_id, :client_id).
        each do |report_cell_id, client_id|
        hash[report_cell_id] ||= []
        hash[report_cell_id] << client_id
      end
    end

    duplicate_ids = []
    cells_with_duplicates.each do |report_cell_id, client_ids|
      candidate_ids = HudReports::UniverseMember.where(report_cell_id: report_cell_id, client_id: client_ids).pluck(:id)
      duplicate_ids += (candidate_ids - [candidate_ids.max])
      puts duplicate_ids.size
    end

    deletion = Date.current.to_time
    HudReports::UniverseMember.where(id: duplicate_ids).update(deleted_at: deletion) if duplicate_ids.size.positive?

    if index_exists? :hud_report_universe_members, [:report_cell_id]
      remove_index :hud_report_universe_members, column: [:report_cell_id]
    end
    add_index :hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type],
      unique: true,
      name: 'uniq_hud_report_universe_members',
      where: 'deleted_at IS NULL'
  end

  def down
    if index_exists? hud_report_universe_members, [:report_cell_id, :universe_membership_id, :universe_membership_type]
      remove_index :hud_report_universe_members, name: :uniq_hud_report_universe_members
    end
  end
end