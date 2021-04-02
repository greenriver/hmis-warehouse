class UniqUniverseMemberships < ActiveRecord::Migration[5.2]
  def up
    cells_with_duplicates = {}.tap do |hash|
      HudReports::UniverseMember.
        group(:report_cell_id, :universe_membership_id, :universe_membership_type).having('count(*) > 1').
        pluck(:report_cell_id, :universe_membership_id, :universe_membership_type).
        each do |report_cell_id, universe_membership_id, universe_membership_type|
        hash[report_cell_id] ||= []
        hash[report_cell_id] << [universe_membership_id, universe_membership_type]
      end
    end

    duplicate_ids = cells_with_duplicates.map do |report_cell_id, rows|
      universe_membership_ids = rows.map(&:first)
      universe_membership_types = rows.map(&:last)
      candidate_ids = HudReports::UniverseMember.where(report_cell_id: report_cell_id, universe_membership_id: universe_membership_ids, universe_membership_type: universe_membership_types).pluck(:id)
      candidate_ids - [candidate_ids.max]
    end.flatten

    deletion = Date.current.to_time
    HudReports::UniverseMember.where(id: duplicate_ids).update(deleted_at: deletion) if duplicate_ids.size.positive?
  end
end
