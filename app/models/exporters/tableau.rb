# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper

  module_function

    def null
      lit 'NULL'
    end
    private_class_method :null

    def vispdat(start_date: 3.years.ago, end_date: DateTime.current, local_planning_group:)
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
        joins( enrollment: [ :service_history_enrollment, { project: :organization } ] ).
        merge( she_t.engine.open_between start_date: start_date, end_date: end_date ).
        where( p_t[:local_planning_group].eq local_planning_group ).
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

    def disability(start_date: 3.years.ago, end_date: DateTime.current, coc_code:)
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

end