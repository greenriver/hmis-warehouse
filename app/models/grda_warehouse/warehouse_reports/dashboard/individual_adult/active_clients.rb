module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        individual_adult(start_date: @range.start, end_date: @range.end)
    end

    # def active_client_service_history range: 
    #   # homeless_service_history_source.entry.
    #   #   joins(:client, :project).
    #   #   open_between(start_date: range.start, end_date: range.end).
    #   #   pluck(*service_history_columns.values).
    #   #   map do |row|
    #   #     Hash[service_history_columns.keys.zip(row)]
    #   #   end.group_by{|m| m[:client_id]}

    #   service_history_source.entry.
    #     joins(:client, :project).
    #     individual_adult.
    #     homeless.
    #     open_between(start_date: range.start, end_date: range.end).
    #     where(
    #       client_id: service_history_source.
    #       homeless.
    #       service_within_date_range(start_date: range.start, end_date: range.end).
    #       distinct.
    #       select(:client_id)
    #     ).
    #     pluck(*service_history_columns.values).
    #     map do |row|
    #       Hash[service_history_columns.keys.zip(row)]
    #     end.select do |row|
    #       # throw out any that start after the range
    #       row[:first_date_in_program] <= range.end
    #     end.
    #     group_by{|m| m[:client_id]}
    # end
  end
end