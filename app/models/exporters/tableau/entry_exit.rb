module Exporters::Tableau::EntryExit
  include ArelHelper
  include TableauExport

  module_function
    def to_csv(start_date: default_start, end_date: default_end, coc_code: nil, path: nil)
      model = she_t.engine

      spec = {
        data_source:                      c_t[:data_source_id],
        personal_id:                      c_t[:PersonalID],
        client_uid:                       she_t[:client_id],
        id:                               she_t[:id],
        entry_exit_uid:                   e_t[:id],
        hh_uid:                           she_t[:head_of_household_id],
        group_uid:                        she_t[:enrollment_group_id],
        head_of_household:                she_t[:head_of_household],
        hh_config:                        she_t[:presented_as_individual],
        prov_id:                          she_t[:project_name],
        _prov_id:                         she_t[:project_id],
        prog_type:                        she_t[model.project_type_column],
        prov_jurisdiction:                site_t[:City],
        entry_exit_entry_date:            she_t[:first_date_in_program],
        entry_exit_exit_date:             she_t[:last_date_in_program],
        client_dob:                       nil,
        client_age_at_entry:              she_t[:age],
        client_6orunder:                  nil,
        client_7to17:                     nil,
        client_18to24:                    nil,
        veteran_status:                   c_t[:VeteranStatus],
        hispanic_latino:                  c_t[:Ethnicity],
        **c_t.engine.race_fields.map{ |f| [ "primary_race_#{f}".to_sym, c_t[f.to_sym] ] }.to_h, # primary race logic is funky
        disabling_condition:              nil,
        any_income_30days:                nil,
        county_homeless:                  null, # ???
        res_prior_to_entry:               e_t[:ResidencePrior],
        length_of_stay_prev_place:        e_t[:ResidencePriorLengthOfStay],
        approx_date_homelessness_started: e_t[:DateToStreetESSH],
        times_on_street:                  e_t[:TimesHomelessPastThreeYears],
        total_months_homeless_on_street:  e_t[:MonthsHomelessPastThreeYears],
        destination:                      she_t[:destination],
        destination_other:                ex_t[:OtherDestination],
        service_uid:                      nil, # Collected from service history
        service_inactive:                 nil, # Collected from service history
        service_code_desc:                nil, # Collected from service history
        service_start_date:               nil, # Collected from service history
        # after this point in the sample data everything is NULL
        entry_exit_uid_1:                 null,
        days_to_return:                   null,
        entry_exit_uid_2:                 null, # REPEAT
        days_last3years:                  null,
        instances_last3years:             null,
        entry_exit_uid_3:                 null, # REPEAT
        rrh_time_in_shelter:              null,
      }

      scope = model.residential.entry.
        open_between( start_date: start_date, end_date: end_date ).
        with_service_between( start_date: start_date, end_date: end_date, service_scope: :service_excluding_extrapolated).
        joins( project: :sites, enrollment: :client ).
        includes(enrollment: :exit).
        references(enrollment: :exit).
        # for aesthetics
        order( she_t[:client_id].asc ).
        order( e_t[:id].asc ).
        order( she_t[:first_date_in_program].desc ).
        order( she_t[:last_date_in_program].desc )


      if coc_code.present?
        scope = scope.merge( pc_t.engine.in_coc coc_code: coc_code )
      end

      spec.each do |header, selector|
        next if selector.nil?
        scope = scope.select selector.as(header.to_s)
      end

      
      if path.present?
        CSV.open path, 'wb', headers: true do |csv|
          export model, spec, scope, end_date, csv
        end
        return true
      else
        CSV.generate headers: true do |csv|
          export model, spec, scope, end_date, csv
        end
      end
    end

    def export model, spec, scope, end_date, csv
      # cleanup headers
      headers = spec.keys.map do |header|
        case header
        when :data_source, :personal_id, :id
          next
        when -> (h) { h.to_s.starts_with? '_' }
          next
        when -> (h) { h.to_s.starts_with? 'primary_race_' }
          :primary_race
        else
          header
        end
      end.compact.uniq

      csv << headers

      thirty_day_limit = end_date - 30.days

      data = model.connection.select_all(scope.to_sql)
      client_ids = data.map{|row| row['client_uid']}
      dobs = c_t.engine.where(id: client_ids).pluck(:id, :DOB).to_h

      data.group_by do |row| 
        row['id'] 
      end.each do |_, (*,row)| # use only the most recent disability record
        # fetch related service history
        enrollment_start = row['entry_exit_entry_date'].to_date
        enrollment_end = row['entry_exit_exit_date'].to_date rescue end_date.to_date
        service_history = shs_t.engine.where(
          service_history_enrollment_id: row['id'],
          record_type: :service,
          date: (enrollment_start..enrollment_end),
          client_id: row['client_uid']
        ).pluck(:id, :service_type, :date).map do |id, service_type, date|
          {
            service_uid: id,
            service_code_desc: service_type,
            service_start_date: date,
          }
        end

        csv_row = []
        headers.each do |h|
          value = row[h.to_s].presence
          value = case h
          when :hh_config
            value == 't' ? 'Single' : 'Family'
          when :prov_id
            "#{value} (#{row['_prov_id']})"
          when :prog_type
            pt = value&.to_i
            if pt
              type = ::HUD.project_type pt
              if type == pt
                pt
              else
                "#{type} (HUD)"
              end
            end
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
          when :client_dob
            dobs[row['client_uid']]
          when :veteran_status
            value&.to_i == 1 ? 't' : 'f'
          when :hispanic_latino
            case value&.to_i
            when 1 then 't'
            when 0 then 'f'
            end
          when :primary_race
            fields = c_t.engine.race_fields.select{ |f| row["primary_race_#{f.downcase}"].to_i == 1 }
            if fields.many?
              'Multiracial'
            elsif fields.any?
              ::HUD.race fields.first
            end
          when :disabling_condition
            if [1,2,3].include? d_t.engine.where(
              ProjectEntryID: row['group_uid'],
              PersonalID: row['personal_id'],
              data_source_id: row['data_source_id'],
            ).order(InformationDate: :desc).limit(1).pluck(:DisabilityResponse).first
              't'
            else
              'f'
            end
          when :res_prior_to_entry
            ::HUD.living_situation value&.to_i
          when :length_of_stay_prev_place
            ::HUD.residence_prior_length_of_stay value&.to_i
          when :destination
            ::HUD.destination value&.to_i
          when :service_uid
            ids = service_history.map{ |hash| hash[h] }
            "{#{ ids.join '|' }}"
          when :service_inactive
            ids = service_history.map{ |hash| 'f' }
            "{#{ ids.join '|' }}"
          when :service_code_desc
            descs = service_history.map{ |hash| ::HUD.record_type hash[h].presence&.to_i }
            "{#{ descs.join '|' }}"
          when :service_start_date
            dates = service_history.map{ |hash| hash[h].presence&.strftime('%F') }
            "{#{ dates.join '|' }}"
          when :any_income_30days
            has_income = GrdaWarehouse::Hud::IncomeBenefit.
              where( 
                PersonalID: row['personal_id'], 
                data_source_id: row['data_source'],
                ProjectEntryID: row['group_uid']
              ).
              where( IncomeFromAnySource: 1 ).
              where( ib_t[:InformationDate].gteq thirty_day_limit ).
              where( ib_t[:InformationDate].lt end_date ).
              exists?
            has_income ? 't' : 'f'
          else
            value
          end
          csv_row << value
        end
        csv << csv_row
      end
    end
  # End Module Functions
end