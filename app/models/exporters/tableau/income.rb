###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::Income
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    model = GrdaWarehouse::Hud::IncomeBenefit

    columns = {
      grouping_variable: she_t[:id],
      entry_exit_uid: e_t[:EnrollmentID],
      entry_exit_client_id: she_t[:client_id],
      earned_income: ib_t[:Earned],
      ssi_ssdi: ib_t[:SSI],
      tanf: ib_t[:TANF],
      source_of_income: ib_t[:SSDI],
      receiving_income_source: ib_t[:IncomeFromAnySource],
      start_date: she_t[:first_date_in_program],
      end_date: she_t[:last_date_in_program],
    }

    scope = model.
      joins(enrollment: [:enrollment_coc_at_entry, :service_history_enrollment]).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(project_types).open_between(start_date: start_date, end_date: end_date)).
      # for aesthetics
      order(she_t[:client_id].asc).
      order(she_t[:first_date_in_program].desc).
      order(she_t[:last_date_in_program].desc).
      # for de-duping
      order(ib_t[:InformationDate].desc)

    scope = scope.where(ec_t[:CoCCode].eq coc_code) if coc_code.present?
    incomes = scope

    columns.each do |header, selector|
      incomes = incomes.select selector.as(header.to_s)
    end

    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        export model, columns, incomes, csv
      end
      return true
    else
      CSV.generate headers: true do |csv|
        export model, columns, incomes, csv
      end
    end
  end

  def export(model, columns, incomes, csv)
    headers = columns.keys - [:grouping_variable]
    csv << headers

    incomes = model.connection.select_all(incomes.to_sql)
    # get the *most recent* ib per enrollment and ignore the rest
    incomes.group_by { |h| h['grouping_variable'] }.each do |_, (income, *)|
      row = []
      ssi, ssdi, tanf, earned_income = ['ssi_ssdi', 'source_of_income', 'tanf', 'earned_income'].map { |f| income[f].presence&.to_i == 1 }
      headers.each do |h|
        value = income[h.to_s].presence
        value = case h
        when :start_date, :end_date
          value && DateTime.parse(value).strftime('%Y-%m-%d')
        when :earned_income
          earned_income ? 'Yes' : 'No'
        when :tanf
          tanf ? 'Yes' : 'No'
        when :ssi_ssdi
          if ssi || ssdi
            'Yes'
          else
            'No'
          end
        when :source_of_income
          # pure guessword
          source = if earned_income
            'Earned Income'
          elsif ssi
            'SSI'
          elsif ssdi
            'SSDI'
          elsif tanf
            'TANF'
          end
          "#{source} (HUD)" if source
        when :receiving_income_source
          value&.to_i == 1 ? 'Yes' : 'No'
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
