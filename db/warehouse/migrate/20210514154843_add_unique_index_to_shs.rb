class AddUniqueIndexToShs < ActiveRecord::Migration[5.2]
  def up
    # NOTE: you may need to run this first
    # loop over all destination clients
    # GrdaWarehouse::Hud::Client.destination.find_each do |client|
    #   to_remove_ids = []
    #   GrdaWarehouse::ServiceHistoryService.where(client_id: client.id).group(:date, :service_history_enrollment_id).
    #     having('count(*) > 1').
    #     select('ARRAY_AGG(id) as agg').each do |shs|
    #       to_remove_ids += shs.agg[0..-2].to_a
    #     end
    #   next if to_remove_ids.blank?

    #   puts "Removing #{to_remove_ids.count} SHS for client: #{client.id}"
    #   GrdaWarehouse::ServiceHistoryService.where(id: to_remove_ids, client_id: client.id).delete_all
    #   client.clear_view_cache
    # end

    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, name|
      replace_index(name, year)
    end
    # Don't forget the remainder
    name = GrdaWarehouse::ServiceHistoryService.remainder_table
    year = 1900
    replace_index(name, year)
  end

  def replace_index(name, year)
    if index_exists?(name, [:date, :service_history_enrollment_id], name: "index_shs_#{year}_date_en_id")
      remove_index name, [:date, :service_history_enrollment_id]
    elsif index_exists?(name, [:service_history_enrollment_id, :date, :record_type], name: "index_shs_#{year}_date_en_id")
      remove_index name, [:service_history_enrollment_id, :date, :record_type]
    end
    add_index name, [:date, :service_history_enrollment_id], name: "index_shs_#{year}_date_en_id", unique: true
  end
end
