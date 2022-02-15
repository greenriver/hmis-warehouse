###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::Vispdat
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    columns = {
      client_uid: e_t[:PersonalID],
      vispdat_1_recordset_id: null,
      vispdat_1_provider: null,
      vispdat_1_start_date: null,
      vispdat_1_grand_total: null,
      vispdat_2_recordset_id: enx_t[:id],
      vispdat_2_provider: o_t[:OrganizationName],
      _pn: p_t[:ProjectName],
      _pid: p_t[:ProjectID],
      vispdat_2_start_date: enx_t[:vispdat_started_at],
      vispdat_2_grand_total: enx_t[:vispdat_grand_total],
      vispdat_fam_recordset_id: null,
      vispdat_fam_provider: null,
      vispdat_fam_start_date: null,
      vispdat_fam_grand_total: null,
    }

    model = GrdaWarehouse::EnrollmentExtra

    scope = model.
      joins(
        enrollment: [
          :enrollment_coc_at_entry,
          :service_history_enrollment,
          { project: :organization },
        ],
      ).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(project_types).open_between(start_date: start_date, end_date: end_date)).
      # for aesthetics
      order(e_t[:PersonalID].asc).
      order(o_t[:OrganizationName]).
      order(p_t[:ProjectName]).
      order(enx_t[:vispdat_started_at])
    scope = scope.where(ec_t[:CoCCode].eq coc_code) if coc_code.present?
    vispdats = scope
    columns.each do |header, selector|
      vispdats = vispdats.select selector.as(header.to_s)
    end

    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        export model, columns, vispdats, csv
      end
      return true
    else
      CSV.generate headers: true do |csv|
        export model, columns, vispdats, csv
      end
    end
  end

  def export model, columns, vispdats, csv
    headers = columns.keys.reject { |k| k.to_s.starts_with? '_' }
    csv << headers

    model.connection.select_all(vispdats.to_sql).each do |vispdat|
      row = []
      headers.each do |h|
        value = vispdat[h.to_s].presence
        value = case h
        when :vispdat_2_provider
          "#{value}: #{vispdat['_pn']} (#{vispdat['_pid']})"
        else
          value
        end
        row << value
      end
      csv << row
    end
  end
  # End Module Functions
end
