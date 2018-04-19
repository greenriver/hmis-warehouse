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
      model = c_t.engine
      spec = {
        client_uid:   she_t[:client_id],
        is_family:    she_t[:presented_as_individual],
        is_veteran:   c_t[:VeteranStatus],
        is_youth:     shs_t[:age],
        is_chronic:   p_t[:id],
        hh_config:    she_t[:presented_as_individual],
        prog1:        she_t[she_t.engine.project_type_column],
        entry1:       she_t[:first_date_in_program],
        exit1:        she_t[:last_date_in_program],
        destination1: she_t[:destination],
        # repeat? -- the sample data varies, so something else is going on
        prog2:        null,
        entry2:       null,
        exit2:        null,
        destination2: null,
        prog3:        null,
        entry3:       null,
        exit3:        null,
        destination3: null,
        prog4:        null,
        entry4:       null,
        exit4:        null,
        destination4: null,
        prog5:        null,
        entry5:       null,
        exit5:        null,
        destination5: null,
        prog6:        null,
        entry6:       null,
        exit6:        null,
        destination6: null,
        link:         null,
      }

      shs_t2 = Arel::Table.new shs_t.table_name
      shs_t2.table_alias = 'shs_t2'
      paths = model.
        joins( service_history_services: { service_history_enrollment: { enrollment: :enrollment_cocs } } ).
        merge(
          # left join *chronic* projects
          she_t.engine.
            includes(:project).
            references(:project).
            merge(p_t.engine.hud_chronic)
        ).
        where( shs_t[:date].gteq start_date ).
        where( shs_t[:date].lt end_date ).
        where(
          # this should be the *most recent* service history service for the client
          shs_t2.project(Arel.star).
            where( shs_t2[:client_id].eq c_t[:id] ).
            where( shs_t2[:id].not_eq shs_t[:id] ).
            where( shs_t2[:date].gteq start_date ).
            where( shs_t2[:date].lt end_date ).
            where( shs_t2[:date].gt shs_t[:date] ).
            exists.not
        ).
        where( ec_t[:DataCollectionStage].eq 1 ).
        where( ec_t[:CoCCode].eq coc_code ).
        order( she_t[:client_id].asc ).
        order( she_t[:first_date_in_program].desc ).
        order( she_t[:last_date_in_program].desc )
      spec.each do |header, selector|
        paths = paths.select selector.as(header.to_s)
      end

      headers = spec.keys
      rows = [headers]

      model.connection.select_all(paths.to_sql).each do |path|
        rows << headers.map do |h|
          value = path[h.to_s].presence
          case h
          when :is_veteran
            value.to_i == 1 ? 't' : 'f' if value
          when :is_youth
            value.to_i.in?(18..24) ? 't' : 'f' if value
          when :is_chronic
            value ? 't' : 'f'
          when :hh_config
            value == 't' ? 'Single' : 'Family'
          when :prog1, :prog2, :prog3, :prog4, :prog5, :prog6
            ::HUD.project_type value.to_i if value
          when :entry1, :entry2, :entry3, :entry4, :entry5, :entry6, :exit1, :exit2, :exit3, :exit4, :exit5, :exit6
            value && DateTime.parse(value).strftime('%Y-%m-%d')
          when :destination1, :destination2, :destination3, :destination4, :destination5, :destination6
            ::HUD.destination value.to_i if value
          when :link
            'link' # ???
          else
            value
          end
        end
      end

      rows
    end
    # private_class_method :pathways_common

end