# stateless collection of functions for creating CSV files ingested by Tableau
module Exporters::Tableau
  include ArelHelper

  module_function

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