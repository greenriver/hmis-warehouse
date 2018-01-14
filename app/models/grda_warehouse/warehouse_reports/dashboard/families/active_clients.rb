module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.family(start_date: @range.start, end_date: @range.end)
    end

    # def active_client_service_history range: 
    #   service_history_source.
    #     joins(:client, :project).
    #     family.
    #     homeless.
    #     open_between(start_date: range.start, end_date: range.end + 1.day).
    #     entry.
    #     where(
    #       client_id: service_history_source.
    #       homeless.
    #       service_within_date_range(start_date: range.start, end_date: range.end + 1.day).
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