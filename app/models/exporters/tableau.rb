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

    def income(start_date: 3.years.ago, end_date: DateTime.current, coc_code:)
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

end