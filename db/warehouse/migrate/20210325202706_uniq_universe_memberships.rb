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

    duplicate_ids = [].tap do |dups|
      cells_with_duplicates.each do |report_cell_id, client_ids|
        candidate_ids = HudReports::UniverseMember.where(report_cell_id: report_cell_id, client_id: client_ids).pluck(:id)
        dups.concat(candidate_ids - [candidate_ids.max])
      end
    end

    deletion = Date.current.to_time
    HudReports::UniverseMember.where(id: duplicate_ids).update(deleted_at: deletion) if duplicate_ids.size.positive?
  end
end