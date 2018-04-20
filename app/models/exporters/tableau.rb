# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper

  module_function

    def null
      lit 'NULL'
    end
    private_class_method :null

    def pathways_with_dest(start_date: 3.years.ago, end_date: DateTime.current, coc_code:)
    end

    def pathways_common(start_date: 3.years.ago, end_date: DateTime.current, coc_code:)
      model = she_t.engine
      spec = {
        client_uid:  she_t[:client_id],
        is_family:   she_t[:presented_as_individual],
        is_veteran:  c_t[:VeteranStatus],
        is_youth:    she_t[:age],
        is_chronic:  she_t[:computed_project_type],
        hh_config:   she_t[:presented_as_individual],
        prog:        she_t[she_t.engine.project_type_column],
        entry:       she_t[:first_date_in_program],
        exit:        she_t[:last_date_in_program],
        destination: she_t[:destination],
      }
      repeaters     = %i( prog entry exit destination )
      non_repeaters = spec.keys - repeaters

      shs_t2 = Arel::Table.new shs_t.table_name
      shs_t2.table_alias = 'shs_t2'
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
      paths = model.connection.select_all(paths.to_sql).group_by{ |h| h['client_uid'] }
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
            value.to_i.in?(p_t.engine::CHRONIC_PROJECT_TYPES) ? 't' : 'f'
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
    # private_class_method :pathways_common

end