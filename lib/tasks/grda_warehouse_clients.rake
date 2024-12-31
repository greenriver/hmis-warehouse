# frozen_string_literal: true

# rubocop:disable Naming/MethodParameterName

require 'csv'

namespace :grda_warehouse do
  namespace :clients do
    # rails grda_warehouse:clients:validate > warehouse_client_issues.csv
    desc 'Report on validation issues in WarehouseClient associations, emits issues a csv'
    task validate: [:environment] do
      CSV do |csv|
        csv << ['warehouse_client_id', 'error_message']
        WarehouseClientValidator.validate do |wc, errors|
          errors.each do |error|
            csv << [wc.id, error]
          end
        end
      end
    end
  end
end

class WarehouseClientValidator
  def self.validate
    destination_data_source_ids = GrdaWarehouse::DataSource.destination_data_source_ids.to_set
    warehouse_clients = GrdaWarehouse::WarehouseClient.preload(:source, :destination)
    destination_client_ids = GrdaWarehouse::WarehouseClient.distinct.pluck(:destination_id).to_set
    warehouse_clients.find_each(batch_size: 1000) do |wc|
      errors = validate_warehouse_client(
        wc,
        destination_data_source_ids,
        destination_client_ids,
      )
      yield(wc, errors) if errors.any?
    end
  end

  def self.validate_warehouse_client(wc, destination_data_source_ids, destination_client_ids)
    errors = []

    # Basic existence and equality checks
    errors << "Source and destination are the same client (ID: #{wc.source_id})" if wc.source_id == wc.destination_id
    errors << "Source client (ID: #{wc.source_id}) does not exist" unless wc.source
    errors << "Destination client (ID: #{wc.destination_id}) does not exist" unless wc.destination

    # Destination-specific checks
    if wc.destination
      errors << "Destination client (ID: #{wc.destination_id}) is not in a destination data source" if wc.destination && destination_data_source_ids.exclude?(wc.destination.data_source_id)
    end

    # Source-specific checks
    if wc.source
      errors << "Source client (ID: #{wc.source_id}) is in a destination data source" if destination_data_source_ids.include?(wc.source.data_source_id)
      errors << "Source client (ID: #{wc.source_id}) does not match warehouse client data source (ID: #{wc.data_source_id})" if wc.data_source_id != wc.source.data_source_id
      errors << "Source client (ID: #{wc.source_id}) is used as a destination in another warehouse client" if destination_client_ids.include?(wc.source_id)
    end

    errors
  end
end

# rubocop:enable Naming/MethodParameterName
