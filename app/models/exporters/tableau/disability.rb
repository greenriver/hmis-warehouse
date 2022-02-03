###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::Disability
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    columns = {
      entry_exit_uid: e_t[:EnrollmentID],
      entry_exit_client_id: she_t[:client_id],
      disability_type: d_t[:DisabilityType],
      start_date: she_t[:first_date_in_program],
      end_date: she_t[:last_date_in_program],
    }

    model = GrdaWarehouse::Hud::Client

    scope = model.
      joins(service_history_enrollments: { enrollment: [:disabilities, :enrollment_coc_at_entry] }).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(project_types).open_between(start_date: start_date, end_date: end_date)).
      where(d_t[:DisabilityResponse].in([1, 2, 3])).
      # for aesthetics
      order(she_t[:client_id].asc).
      order(she_t[:first_date_in_program].desc).
      order(she_t[:last_date_in_program].desc).
      # for de-duping
      order(d_t[:InformationDate].desc)

    scope = scope.where(ec_t[:CoCCode].eq coc_code) if coc_code.present?
    clients = scope

    columns.each do |header, selector|
      clients = clients.select selector.as(header.to_s)
    end

    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        export model, columns, clients, csv
      end
      return true
    else
      CSV.generate headers: true do |csv|
        export model, columns, clients, csv
      end
    end
  end

  def export(model, columns, clients, csv)
    headers = columns.keys
    csv << headers

    clients = model.connection.select_all(clients.to_sql).group_by do |h|
      h.values_at('entry_exit_uid', 'entry_exit_client_id', 'start_date', 'end_date')
    end
    # after sorting and grouping, we keep only the most recent disability record
    clients.each do |_, (client, *)|
      row = []
      headers.each do |h|
        value = client[h.to_s].presence
        value = case h
        # when :disability_type
        #   ::HUD.disability_type(value&.to_i)&.titleize
        when :start_date, :end_date
          value && DateTime.parse(value).strftime('%Y-%m-%d')
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
