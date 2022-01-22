###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Exporters::Tableau::EntryExit
  include ArelHelper
  include TableauExport

  module_function

  def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
    model = GrdaWarehouse::ServiceHistoryEnrollment
    export_scope = scope_for_export(start_date: default_start, end_date: default_end, coc_code: coc_code)

    if path.present?
      CSV.open path, 'wb', headers: true do |csv|
        export(model, columns, export_scope, start_date, end_date, csv)
      end
      return true
    else
      CSV.generate headers: true do |csv|
        export(model, columns, export_scope, start_date, end_date, csv)
      end
    end
  end

  def columns
    model = GrdaWarehouse::ServiceHistoryEnrollment
    @columns ||= {
      data_source: she_t[:data_source_id],
      personal_id: c_t[:PersonalID],
      client_uid: she_t[:client_id], # in use
      id: she_t[:id],
      entry_exit_uid: e_t[:id], # in use
      hh_uid: e_t[:HouseholdID], # in use
      # group_uid:                        she_t[:enrollment_group_id],
      # head_of_household:                she_t[:head_of_household],
      hh_config: she_t[:presented_as_individual], # in use
      rel_to_hoh: e_t[:RelationshipToHoH], # in use
      prov_id: she_t[:project_name], # in use
      _prov_id: she_t[:project_id], # in use
      prog_type: she_t[model.project_type_column], # in use
      coc_code: pc_t[:CoCCode], # in use
      entry_exit_entry_date: she_t[:first_date_in_program], # in use
      entry_exit_exit_date: she_t[:last_date_in_program], # in use
      client_age_at_entry: she_t[:age], # in use
      # client_6orunder:                  nil,
      # client_7to17:                     nil,
      # client_18to24:                    nil,
      veteran_status: c_t[:VeteranStatus], # in use
      gender: c_t[:Gender], # in use
      hispanic_latino: c_t[:Ethnicity],
      **GrdaWarehouse::Hud::Client.race_fields.map { |f| ["primary_race_#{f}".to_sym, c_t[f.to_sym]] }.to_h, # primary race logic is funky # in use
      # disabling_condition:              nil,
      # any_income_30days:                nil,
      res_prior_to_entry: e_t[:LivingSituation],
      length_of_stay_prev_place: e_t[:LengthOfStay],
      approx_date_homelessness_started: e_t[:DateToStreetESSH],
      times_on_street: e_t[:TimesHomelessPastThreeYears],
      total_months_homeless_on_street: e_t[:MonthsHomelessPastThreeYears],
      destination: she_t[:destination], # in use
      destination_other: ex_t[:OtherDestination],
      tracking_method: she_t[:project_tracking_method],
      # night_before_es_sh:               nil,
      # less_than_7_nights:               nil,
      # less_than_90_days:                nil,
      movein_date: e_t[:MoveInDate], # in use
      chronic: nil, # at date of enrollment start # in use
      chronic_at_entry: nil, # chronic based on self-report # in use
      days_to_return: nil, # if exit destination is PH, count days until next ES, SH, SO, TH, PH as described in SPM Measure 2a # in use
      rrh_time_in_shelter: nil, # in use
      _date_to_street_es_sh: e_t[:DateToStreetESSH], # in use
      prior_es_enrollment_last3_count: nil, # in use
      local_planning_group: p_t[:local_planning_group], # in use
      confidential: p_t[:confidential], # in use
      coc_name: nil, # in use
    }
  end

  def scope_for_export(start_date: default_start, end_date: default_end, coc_code: nil)
    model = GrdaWarehouse::ServiceHistoryEnrollment

    export_scope = model.in_project_type(project_types).entry.
      open_between(start_date: start_date, end_date: end_date).
      # with_service_between(start_date: start_date, end_date: end_date, service_scope: :service_excluding_extrapolated).
      joins(enrollment: :client).
      includes(enrollment: [:exit, project: :project_cocs]).
      references(enrollment: [:exit, project: :project_cocs]).
      # for aesthetics
      order(she_t[:client_id].asc)
    # order( e_t[:id].asc ).
    # order( she_t[:first_date_in_program].desc ).
    # order( she_t[:last_date_in_program].desc )

    export_scope = export_scope.merge(GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_code)) if coc_code.present?

    export_scope
  end

  def export(model, columns, export_scope, start_date, end_date, csv) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/UnusedMethodArgument
    # Fetch a client id list for batch processing
    client_ids = export_scope.distinct.pluck(:client_id)

    # cleanup headers
    headers = columns.keys.map do |header|
      case header
      when :data_source, :personal_id, :id
        next
      when ->(h) { h.to_s.starts_with? '_' }
        next
      when ->(h) { h.to_s.starts_with? 'primary_race_' }
        :primary_race
      else
        header
      end
    end.compact.uniq

    csv << headers

    thirty_day_limit = end_date - 30.days

    disabled_ids = Rails.cache.fetch('entry-exit-disabled-client-ids', expires_in: 2.hours) do
      GrdaWarehouse::Hud::Client.disabled_client_ids
    end

    # tell arel what columns to pluck
    columns.each do |header, selector|
      next if selector.nil?

      export_scope = export_scope.select selector.as(header.to_s)
    end

    batch_size = 2_500
    start_time = Time.now
    client_ids.each_slice(batch_size).with_index do |batch_client_ids, i|
      elapsed_seconds = Time.now - start_time
      elapsed = Time.at(elapsed_seconds).utc.strftime('%H h %M m')
      Rails.logger.debug "DEBUG Processing batch of clients: #{(i + 1) * batch_size} elapsed time: #{elapsed}"
      # Add additional ordering
      export_scope = export_scope.order(e_t[:id].asc).
        order(she_t[:first_date_in_program].desc).
        order(she_t[:last_date_in_program].desc)
      data = model.connection.select_all(export_scope.where(she_t[:client_id].in(batch_client_ids)).to_sql)
      # dobs = GrdaWarehouse::Hud::Client.where(id: batch_client_ids).pluck(:id, :DOB).to_h

      clients = GrdaWarehouse::Hud::Client.where(id: batch_client_ids).index_by(&:id)
      data_by_client = data.group_by do |row|
        row['client_uid']
      end
      batch_enrollment_ids = data.map { |row| row['entry_exit_uid'] }.uniq
      enrollments = GrdaWarehouse::Hud::Enrollment.where(id: batch_enrollment_ids).index_by(&:id)
      ph_th = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      data.group_by do |row|
        row['id']
      end.each do |_, (*, row)| # use only the most recent disability record
        # fetch related service history
        # enrollment_start = row['entry_exit_entry_date'].to_date
        # enrollment_end = row['entry_exit_exit_date'].to_date rescue end_date.to_date
        # service_history = shs_t.engine.where(
        #   service_history_enrollment_id: row['id'],
        #   record_type: :service,
        #   date: (enrollment_start..enrollment_end),
        #   client_id: row['client_uid']
        # ).pluck(:id, :service_type, :date).map do |id, service_type, date|
        #   {
        #     service_uid: id,
        #     service_code_desc: service_type,
        #     service_start_date: date,
        #   }
        # end

        csv_row = []
        headers.each do |h|
          value = row[h.to_s].presence
          value = case h
          when :hh_config
            if value == 't' then 'Single' else 'Family' end
          when :hh_uid
            # HUD Spec columnsifies a new HouseholdID for every enrollment, we'll collapse those for individuals
            # to keep the noise down in the dashboard
            if row['hh_config'] == 't'
              "c_#{row['client_uid']}"
            else
              "#{value}_#{row['data_source']}"
            end
          # when :rel_to_hoh
          #   ::HUD.relationship_to_hoh value&.to_i
          when :prov_id
            if row['confidential'] == 't'
              "#{GrdaWarehouse::Hud::Project.confidential_project_name} (#{HUD.project_type_brief(row['prog_type']&.to_i)})"
            else
              "#{value} (#{row['_prov_id']})"
            end
          # when :prog_type
          #   pt = value&.to_i
          #   if pt
          #     type = ::HUD.project_type pt
          #     if type == pt
          #       pt
          #     else
          #       "#{type} (HUD)"
          #     end
          #   end
          # when :times_on_street
          #   ::HUD.times_homeless_past_three_years_brief value&.to_i
          # when :total_months_homeless_on_street
          #   ::HUD.months_homeless_past_three_years_brief value&.to_i
          when :night_before_es_sh
            entering_from_es = ::HUD.institutional_destinations + ::HUD.temporary_destinations
            entering_from_ph = ::HUD.permanent_destinations
            if entering_from_es.include? row['res_prior_to_entry']&.to_i
              'Yes'
            elsif entering_from_ph.include? row['res_prior_to_entry']&.to_i
              'No'
            end
          when :less_than_7_nights
            'Yes' if ::HUD.residence_prior_length_of_stay_brief value&.to_i == '0-7'
          when :less_than_90_days
            'Yes' if ['7-30', '30-90'].include?(::HUD.residence_prior_length_of_stay_brief(value&.to_i))
          when :client_6orunder
            age = row['client_age_at_entry'].presence&.to_i
            if age && age <= 6
              't'
            else
              'f'
            end
          when :client_7to17
            age = row['client_age_at_entry'].presence&.to_i
            if (7..17).include? age
              't'
            else
              'f'
            end
          when :client_18to24
            age = row['client_age_at_entry'].presence&.to_i
            if (18..24).include? age
              't'
            else
              'f'
            end
          when :veteran_status
            value&.to_i == 1 ? 't' : 'f'
          when :hispanic_latino
            case value&.to_i
            when 1 then 't'
            when 0 then 'f'
            end
          when :primary_race
            fields = GrdaWarehouse::Hud::Client.race_fields.select { |f| row["primary_race_#{f.downcase}"].to_i == 1 }
            if fields.many?
              'Multiracial'
            elsif fields.any?
              ::HUD.race fields.first
            end
          when :disabling_condition
            if disabled_ids.include?(row['client_uid'].to_i)
              't'
            else
              'f'
            end
          when :chronic
            # you can't be chronic if you aren't disabled
            if disabled_ids.include?(row['client_uid'].to_i)
              client = clients[row['client_uid'].to_i]
              if client.hud_chronic?(on_date: row['entry_exit_entry_date'].to_date) then 't' else 'f' end
            else
              'f'
            end
          when :chronic_at_entry
            if enrollments[row['entry_exit_uid']].chronically_homeless_at_start? then 't' else 'f' end
          when :any_income_30days
            has_income = GrdaWarehouse::Hud::IncomeBenefit.
              where(
                PersonalID: row['personal_id'],
                data_source_id: row['data_source'],
                EnrollmentID: row['group_uid'],
              ).
              where(IncomeFromAnySource: 1).
              where(ib_t[:InformationDate].gteq(thirty_day_limit)).
              where(ib_t[:InformationDate].lt(end_date)).
              exists?
            has_income ? 't' : 'f'
          when :days_to_return
            # Verify that if a client has two exits on the same day, they should have the same days to return

            # if exit destination is PH, count days until next ES, SH, SO, TH, PH as described in SPM Measure 2a
            # nil - no exit
            # positive number = days to return
            # -1 = no return
            if ::HUD.permanent_destinations.include? row['destination'].to_i
              # select all residential enrollments where the entry date is greater than this exit date
              # if the next enrollment is TH it must be > 14 days after exit to count
              # if the next enrollment is PH it must be > 14 days after exit AND 14 days after any other PH or TH exits
              exit_date = row['entry_exit_exit_date'].to_date
              newer_residential_enrollments = data_by_client[row['client_uid']].select do |enrollment|
                residential = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS.include?(enrollment['prog_type'].to_i)
                residential && enrollment['entry_exit_entry_date'].to_date > exit_date
              end.sort_by do |enrollment|
                # order by entry date and project type, this will put ES in front of PH/TH
                # if they start on the same day
                [enrollment['entry_exit_entry_date'], enrollment['prog_type'].to_i]
              end
              if newer_residential_enrollments.empty?
                -1
              else
                next_enrollment = newer_residential_enrollments.first
                next_entry_date = next_enrollment['entry_exit_entry_date'].to_date
                if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th].include?(next_enrollment['prog_type'].to_i)
                  (next_entry_date - exit_date).to_i if next_entry_date > exit_date + 14.days
                elsif  GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(next_enrollment['prog_type'].to_i)
                  if next_entry_date > exit_date + 14.days
                    # there are no other TH or PH (this is the only newer enrollment)
                    if newer_residential_enrollments.size == 1
                      (next_entry_date - exit_date).to_i
                    else
                      max_other_ph_th_exit_dates = newer_residential_enrollments.drop(1).select do |enrollment|
                        ph_th.include?(enrollment['prog_type'].to_i)
                      end.map do |enrollment|
                        enrollment['entry_exit_exit_date']&.to_date
                      end.compact.max
                      (next_entry_date - exit_date).to_i if max_other_ph_th_exit_dates.present? && next_entry_date > max_other_ph_th_exit_dates + 14.days
                    end
                  end
                else # Not TH or PH
                  (next_entry_date - exit_date).to_i
                end
              end
            end
          when :rrh_time_in_shelter
            # only calculate for RRH
            if row['prog_type']&.to_i == 13 && row['_date_to_street_es_sh'].present?
              begin
                (row['entry_exit_entry_date'].to_date - row['_date_to_street_es_sh'].to_date).to_i
              rescue StandardError
                nil
              end
            end
          when :prior_es_enrollment_last3_count
            entry_date = row['entry_exit_entry_date'].to_date
            three_years_prior = entry_date - 3.years
            data_by_client[row['client_uid']].select do |enrollment|
              GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es].include?(enrollment['prog_type'].to_i) &&
              (three_years_prior...entry_date).include?(enrollment['entry_exit_entry_date'].to_date)
            end.count
          when :coc_name
            ::HUD.coc_name(row['coc_code'])
          else
            value
          end
          csv_row << value
        end
        csv << csv_row
      end
    end # end batch loop
  end
  # End Module Functions
end
