# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper

  module_function

    def default_start
      3.years.ago
    end
    private_class_method :default_start

    def default_end
      DateTime.current
    end
    private_class_method :default_end

    def null
      lit 'NULL'
    end
    private_class_method :null

    def pathways_with_dest(start_date: default_start, end_date: default_end, coc_code:)
      CSV.generate headers: true do |csv|
        pathways_common( start_date: start_date, end_date: end_date, coc_code: coc_code ).each do |row|
          csv << row
        end
      end
    end

    def pathways(start_date: default_start, end_date: default_end, coc_code:)
      # make the recurring boilerplate
      # why is this here? we do not know
      path1 = (0..48).to_a
      path2 = 97.step( 49, -1 ).to_a
      t     = -6.0.step( 6, 0.25 ).to_a
      mins  = %w[min]  * 49
      maxs  = %w[max]  * 49
      links = %w[link] * 49
      boilerplate = ( path1 + path2 ).zip( t + t ).zip( mins + maxs ).zip( links + links ).map(&:flatten)
      # get the real data which will be cross-producted with the boilerplate
      data = pathways_common start_date: start_date, end_date: end_date, coc_code: coc_code
      # add boilerplate headers
      headers = %i( path t minmax link ) + data.shift
      # do the cross product
      CSV.generate headers: true do |csv|
        csv << headers
        data.each do |data_row|
          boilerplate.each do |boilerplate_row|
            csv << boilerplate_row + data_row
          end
        end
      end
    end

    def pathways_common(start_date: default_start, end_date: default_end, coc_code:)
      model = she_t.engine
      spec = {
        client_uid:  she_t[:client_id],
        is_family:   she_t[:presented_as_individual],
        is_veteran:  c_t[:VeteranStatus],
        is_youth:    she_t[:age],
        is_chronic:  c_t[:id],
        hh_config:   she_t[:presented_as_individual],
        prog:        she_t[she_t.engine.project_type_column],
        entry:       she_t[:first_date_in_program],
        exit:        she_t[:last_date_in_program],
        destination: she_t[:destination],
      }
      repeaters     = %i( prog entry exit destination )
      non_repeaters = spec.keys - repeaters

      paths = model.
        joins( :client, enrollment: :enrollment_cocs ).
        # merge( model.hud_residential ). # maybe spurious?
        merge(
          model.
            open_between( start_date: start_date, end_date: end_date ).
            with_service_between( start_date: start_date, end_date: end_date )
        ).
        where( ec_t[:DataCollectionStage].eq 1 ).
        where( ec_t[:CoCCode].eq coc_code ).
        order( she_t[:client_id].asc ).
        order( she_t[:first_date_in_program].asc ).
        order( she_t[:last_date_in_program].asc )
      spec.each do |header, selector|
        paths = paths.select selector.as(header.to_s)
      end

      # each row may represent multiple enrollments
      # each enrollment is represented by a set of the repeater headers suffixed with a one-based index
      # we collect the rows and then pad them with nils, as needed so they are all the same width
      paths = model.connection.select_all(paths.to_sql)
      clients = GrdaWarehouse::Hud::Client.where( id: paths.map{ |h| h['is_chronic'] }.uniq ).index_by(&:id)
      paths = paths.group_by{ |h| h['client_uid'] }
      max_entries = 1
      rows = []
      headers = Set[*non_repeaters]

      paths.each do |_,paths|
        path = paths.last # get the common data from the most recent enrollment
        row = []
        non_repeaters.map do |h|
          value = path[h.to_s].presence
          value = case h
          when :is_veteran
            value.to_i == 1 ? 't' : 'f' if value
          when :is_youth
            value.to_i.in?(18..24) ? 't' : 'f' if value
          when :is_chronic
            client = clients[value.to_i]
            client.hud_chronic?( on_date: start_date ) ? 't' : 'f'
          when :hh_config
            value == 't' ? 'Single' : 'Family'
          else
            value
          end
          row << value
        end

        paths.each_with_index do |path, i|
          repeaters.each do |h|
            headers << "#{h}#{ i + 1 }".to_sym
            value = path[h.to_s].presence
            value = case h
            when :prog
              ::HUD.project_type value.to_i if value
            when :entry, :exit
              value && DateTime.parse(value).strftime('%Y-%m-%d')
            when :destination
              ::HUD.destination value.to_i if value
            else
              value
            end
            row << value
          end
        end

        rows << row
      end
      # pad the rows
      rows.each do |row|
        row.concat Array.new headers.length - row.length, nil
        row << 'link'
      end

      # add pointless link header
      headers << :link
      rows.unshift headers.to_a
      rows
    end
    private_class_method :pathways_common

    def disability(start_date: default_start, end_date: default_end, coc_code:)
      spec = {
        entry_exit_uid:       e_t[:ProjectEntryID],
        entry_exit_client_id: she_t[:client_id],
        disability_type:      d_t[:DisabilityType],
        start_date:           she_t[:first_date_in_program],
        end_date:             she_t[:last_date_in_program],
      }

      model = c_t.engine

      clients = model.
        joins( service_history_enrollments: { enrollment: [ :disabilities, :enrollment_coc_at_entry ] } ).
        merge( she_t.engine.open_between start_date: start_date, end_date: end_date ).
        where( ec_t[:CoCCode].eq coc_code ).
        where( d_t[:DisabilityResponse].in [1,2,3] ).
        # for aesthetics
        order( she_t[:client_id].asc ).
        order( she_t[:first_date_in_program].desc ).
        order( she_t[:last_date_in_program].desc ).
        # for de-duping
        order( d_t[:InformationDate].desc )
      spec.each do |header, selector|
        clients = clients.select selector.as(header.to_s)
      end

      CSV.generate headers: true do |csv|
        headers = spec.keys
        csv << headers

        clients = model.connection.select_all(clients.to_sql).group_by do |h|
          h.values_at %w( entry_exit_uid entry_exit_client_id start_date end_date )
        end
        # after sorting and grouping, we keep only the most recent disability record
        clients.each do |_,(client,*)|
          row = []
          headers.each do |h|
            value = client[h.to_s].presence
            value = case h
            when :disability_type
              ::HUD.disability_type(value&.to_i)&.titleize
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
    end

    def income(start_date: default_start, end_date: default_end, coc_code:)
      model = ib_t.engine

      spec = {
        grouping_variable:       she_t[:id],
        entry_exit_uid:          e_t[:ProjectEntryID],
        entry_exit_client_id:    she_t[:client_id],
        earned_income:           ib_t[:Earned],
        ssi_ssdi:                ib_t[:SSI],
        tanf:                    ib_t[:TANF],
        source_of_income:        ib_t[:SSDI],
        receiving_income_source: ib_t[:IncomeFromAnySource],
        start_date:              she_t[:first_date_in_program],
        end_date:                she_t[:last_date_in_program],
      }

      incomes = model.
        joins( enrollment: [ :enrollment_coc_at_entry, :service_history_enrollment ] ).
        merge( she_t.engine.open_between start_date: start_date, end_date: end_date ).
        where( ec_t[:CoCCode].eq coc_code ).
        # for aesthetics
        order(she_t[:client_id].asc).
        order(she_t[:first_date_in_program].desc).
        order(she_t[:last_date_in_program].desc).
        # for de-duping
        order(ib_t[:InformationDate].desc)
      spec.each do |header, selector|
        incomes = incomes.select selector.as(header.to_s)
      end

      csv = CSV.generate headers: true do |csv|
        headers = spec.keys - [:grouping_variable]
        csv << headers

        incomes = model.connection.select_all(incomes.to_sql)
        # get the *most recent* ib per enrollment and ignore the rest
        incomes.group_by{ |h| h['grouping_variable'] }.each do |_,(income,*)|
          row = []
          ssi, ssdi, tanf, earned_income = %w( ssi_ssdi source_of_income tanf earned_income ).map{ |f| income[f].presence&.to_i == 1 }
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
    end

    def entry_exit(start_date: default_start, end_date: default_end, coc_code: nil)
      model = she_t.engine

      spec = {
        data_source:                      c_t[:data_source_id],
        personal_id:                      c_t[:PersonalID],
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
        any_income_30days:                nil,
        county_homeless:                  null, # ???
        res_prior_to_entry:               e_t[:ResidencePrior],
        length_of_stay_prev_place:        e_t[:ResidencePriorLengthOfStay],
        approx_date_homelessness_started: e_t[:DateToStreetESSH],
        times_on_street:                  e_t[:TimesHomelessPastThreeYears],
        total_months_homeless_on_street:  e_t[:MonthsHomelessPastThreeYears],
        destination:                      she_t[:destination],
        destination_other:                ex_t[:OtherDestination],
        service_uid:                      shs_t[:id],
        service_inactive:                 null, # ???
        service_code_desc:                shs_t[:service_type],
        service_start_date:               shs_t[:date],
        # after this point in the sample data everything is NULL
        entry_exit_uid:                   null,
        days_to_return:                   null,
        entry_exit_uid:                   null, # REPEAT
        days_last3years:                  null,
        instances_last3years:             null,
        entry_exit_uid:                   null, # REPEAT
        rrh_time_in_shelter:              null,
      }

      scope = model.residential.entry.
        open_between( start_date: start_date, end_date: end_date ).
        joins( :client, :service_history_services ).
        joins( project: :sites, enrollment: :exit ).
        includes( client: :source_disabilities ).
        references( client: :source_disabilities ).
        # for aesthetics
        order( she_t[:client_id].asc ).
        order( e_t[:id].asc ).
        order( she_t[:first_date_in_program].desc ).
        order( she_t[:last_date_in_program].desc ).
        order( shs_t[:id].asc )


      scope = if coc_code.present?
        scope.merge( pc_t.engine.in_coc coc_code: coc_code )
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
        when :data_source, :personal_id
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

        thirty_day_limit = end_date - 30.days
        model.connection.select_all(scope.to_sql).group_by{ |h| h.values_at 'client_uid', 'entry_exit_uid' }.each do |_,shes|
          she = shes.first # for values that don't need aggregation
          # de-dupe remainder by service_uid
          shes = shes.group_by{ |h| h['service_uid'] }.map{ |_,(h,*)| h }
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
            when :any_income_30days
              has_income = GrdaWarehouse::Hud::IncomeBenefit.
                where( PersonalID: she['personal_id'], data_source_id: she['data_source'] ).
                where( IncomeFromAnySource: 1 ).
                where( ib_t[:InformationDate].gteq thirty_day_limit ).
                where( ib_t[:InformationDate].lt end_date ).
                exists?
              has_income ? 't' : 'f'
            else
              value
            end
            row << value
          end
          csv << row
        end
      end
    end

    def vispdat(start_date: default_start, end_date: default_end, coc_code:)
      spec = {
        client_uid:               e_t[:PersonalID],
        vispdat_1_recordset_id:   null,
        vispdat_1_provider:       null,
        vispdat_1_start_date:     null,
        vispdat_1_grand_total:    null,
        vispdat_2_recordset_id:   enx_t[:id],
        vispdat_2_provider:       o_t[:OrganizationName],
        _pn:                      p_t[:ProjectName],
        _pid:                     p_t[:ProjectID],
        vispdat_2_start_date:     enx_t[:vispdat_started_at],
        vispdat_2_grand_total:    enx_t[:vispdat_grand_total],
        vispdat_fam_recordset_id: null,
        vispdat_fam_provider:     null,
        vispdat_fam_start_date:   null,
        vispdat_fam_grand_total:  null,
      }

      model = enx_t.engine

      vispdats = model.
        joins(
          enrollment: [
            :enrollment_coc_at_entry,
            :service_history_enrollment,
            { project: :organization }
          ]
        ).
        merge( she_t.engine.open_between start_date: start_date, end_date: end_date ).
        where( ec_t[:CoCCode].eq coc_code ).
        # for aesthetics
        order( e_t[:PersonalID].asc ).
        order( o_t[:OrganizationName] ).
        order( p_t[:ProjectName] ).
        order( enx_t[:vispdat_started_at] )
      spec.each do |header, selector|
        vispdats = vispdats.select selector.as(header.to_s)
      end

      CSV.generate headers: true do |csv|
        headers = spec.keys.reject{ |k| k.to_s.starts_with? '_' }
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
    end

end