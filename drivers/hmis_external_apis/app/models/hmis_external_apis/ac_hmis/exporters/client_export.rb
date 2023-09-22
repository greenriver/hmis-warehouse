###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Exporters
  class ClientExport
    attr_accessor :output

    def initialize(output = StringIO.new)
      require 'csv'
      self.output = output
    end

    def run!
      Rails.logger.info 'Generating content of client export'

      write_row(columns)
      total = clients.count

      Rails.logger.error "There are #{total} clients to export. That doesn't look right" if total < 10

      seen = Set.new
      clients.find_each.with_index do |client, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        warehouse_id = client.warehouse_id
        next unless warehouse_id.present?
        next if seen.include?(warehouse_id)

        seen << warehouse_id

        client_values = [warehouse_id]

        # If the client has multiple MCI IDs, it doesn't matter which one we send
        external_id_values = [client.ac_hmis_mci_ids&.first&.value]

        best_address = client.addresses.to_a.max_by(&:DateUpdated)

        address_values = address_columns.map do |col|
          best_address&.send(col)
        end

        write_row(client_values + external_id_values + address_values)
      end
    end

    private

    def client_columns
      ['PersonalID']
    end

    def external_id_columns
      ['MciID']
    end

    def address_columns
      ['line1', 'line2', 'city', 'state', 'district', 'postal_code']
    end

    def columns
      client_columns + external_id_columns + address_columns
    end

    def write_row(row)
      output << CSV.generate_line(row, **csv_config)
    end

    def csv_config
      {
        write_converters: ->(value, _) {
          if value.instance_of?(Date)
            value.strftime('%Y-%m-%d')
          elsif value.respond_to?(:strftime)
            value.strftime('%Y-%m-%d %H:%M:%S')
          else
            value
          end
        },
      }
    end

    def clients
      Hmis::Hud::Client.
        where(data_source: data_source).
        joins(:warehouse_client_source).
        preload(:warehouse_client_source).
        preload(:addresses).
        preload(:ac_hmis_mci_ids)
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end
