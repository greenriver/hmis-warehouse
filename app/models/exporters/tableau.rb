# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper

  module_function

    def entry_exit(start_date: 3.years.ago, end_date: DateTime.current, coc_code: nil)
      model = she_t.engine

      spec = {
        client_uid:                       she_t[:client_id],
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
        client_dob:                       c_t[:DOB],
        client_age_at_entry:              she_t[:age],
        client_6orunder:                  nil,
        client_7to17:                     nil,
        client_18to24:                    nil,
        veteran_status:                   c_t[:VeteranStatus],
        hispanic_latino:                  c_t[:Ethnicity],
        **c_t.engine.race_fields.map{ |f| [ "primary_race_#{f}".to_sym, c_t[f.to_sym] ] }.to_h, # primary race logic is funky
        disabling_condition:              d_t[:DisabilitiesID],
        any_income_30days:                nil, # ???
        county_homeless:                  nil, # ???
        res_prior_to_entry:               e_t[:ResidencePrior],
        length_of_stay_prev_place:        e_t[:ResidencePriorLengthOfStay],
        approx_date_homelessness_started: e_t[:DateToStreetESSH],
        times_on_street:                  e_t[:TimesHomelessPastThreeYears],
        total_months_homeless_on_street:  e_t[:MonthsHomelessPastThreeYears],
        destination:                      she_t[:destination],
        destination_other:                ex_t[:OtherDestination],
        service_uid:                      shs_t[:id],
        service_inactive:                 nil, # ???
        service_code_desc:                shs_t[:service_type],
        service_start_date:               shs_t[:date],
        entry_exit_uid:                   nil, # ???
        days_to_return:                   nil, # ???
        entry_exit_uid:                   nil, # ??? REPEAT
        days_last3years:                  nil, # ???
        instances_last3years:             nil, # ???
        entry_exit_uid:                   nil, # ??? REPEAT
        rrh_time_in_shelter:              nil, # ???
      }

      scope = model.residential.entry.
        open_between( start_date: start_date, end_date: end_date ).
        joins( :client, :service_history_services ).
        joins( project: :sites, enrollment: :exit ).
        includes( client: :source_disabilities ).
        references( client: :source_disabilities )

      scope = case coc_code
      when Array
        scope.where( pc_t[:CoCCode].in coc_code )
      when String
        scope.where( pc_t[:CoCCode].eq coc_code )
      else
        scope
      end

      spec.each do |header, selector|
        next if selector.nil?
        scope = scope.select selector.as(header.to_s)
      end

      # dump the things we don't know how to deal with and munge a bit
      headers = spec.keys.map do |header|
        case header
        when :any_income_30days, :county_homeless, :entry_exit_uid, :days_to_return, :days_last3years, :instances_last3years, :rrh_time_in_shelter
          next
        when -> (h) { h.to_s.starts_with? '_' }
          next
        when -> (h) { h.to_s.starts_with? 'primary_race_' }
          :primary_race
        else
          header
        end
      end.compact.uniq

      csv = CSV.generate headers: true do |csv|
        csv << headers

        model.connection.select_all(scope.to_sql).group_by{ |h| h.values_at 'client_uid', 'entry_exit_uid' }.each do |_,shes|
          she = shes.first # for values that don't need aggregation
          row = []
          headers.each do |h|
            value = she[h.to_s].presence
            value = case h
            when :hh_config
              value == 't' ? 'Single' : 'Family'
            when :prov_id
              "#{value} (#{she['_prov_id']})"
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
              age = she['client_age_at_entry'].presence&.to_i
              age && age <= 6
            when :client_7to17
              age = she['client_age_at_entry'].presence&.to_i
              (7..17).include? age
            when :client_18to24
              age = she['client_age_at_entry'].presence&.to_i
              (18..24).include? age
            when :veteran_status
              value&.to_i == 1 ? 't' : 'f'
            when :hispanic_latino
              case value&.to_i
              when 1 then 't'
              when 0 then 'f'
              end
            when :primary_race
              fields = c_t.engine.race_fields.select{ |f| she["primary_race_#{f.downcase}"].to_i == 1 }
              if fields.many?
                'Multiracial'
              elsif fields.any?
                ::HUD.race fields.first
              end
            when :disabling_condition
              value ? 't' : 'f'
            when :res_prior_to_entry
              ::HUD.living_situation value&.to_i
            when :length_of_stay_prev_place
              ::HUD.residence_prior_length_of_stay value&.to_i
            when :destination
              ::HUD.destination value&.to_i
            when :service_uid
              ids = shes.map{ |hash| hash[h.to_s] }
              "{#{ ids.join ',' }}"
            when :service_code_desc
              descs = shes.map{ |hash| ::HUD.record_type hash[h.to_s].presence&.to_i }
              "{#{ descs.join ',' }}"
            when :service_start_date
              dates = shes.map{ |hash| hash[h.to_s].presence }
              "{#{ dates.join ',' }}"
            else
              value
            end
            row << value
          end
          csv << row
        end

    end
  end
    
end