###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial
  class Client < ::GrdaWarehouseBase
    self.table_name = :financial_clients

    include HasPiiAttributes
    pii_attr :client_first_name, as: :first_name
    pii_attr :client_last_name, as: :last_name
    pii_attr :client_birthdate, as: :dob
    pii_attr :address_line_1, as: :geo_street
    pii_attr :address_line_2, as: :geo_street
    pii_attr :city, as: :geo_locality
    pii_attr :state, as: :geo_admin_1
    pii_attr :zip_code, as: :geo_postal_code

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :transactions, foreign_key: :external_client_id

    def name
      client_first_name + ' ' + client_last_name
    end

    # Search for matching destination clients, set client_id when match is found
    def self.match_warehouse_clients
      matched = []
      where(client_id: nil).find_each do |client|
        # First check for PersonalID match
        client.client_id = ::GrdaWarehouse::Hud::Client.source.
          find_by(personal_id: client.hmis_id_if_applicable)&.
          destination_client&.
          id
        if client.client_id
          matched << client
          next
        end

        # Find a match based on exact match of name, and DOB
        client.client_id = ::GrdaWarehouse::Hud::Client.source.
          find_by(
            c_t[:FirstName].matches(client.client_first_name&.downcase),
            c_t[:LastName].matches(client.client_last_name&.downcase),
            dob: client.client_birthdate&.to_date,
          )&.
          destination_client&.
          id
        matched << client if client.client_id
      end
      import(
        matched,
        timestamps: false,
        on_duplicate_key_update: {
          columns: [:client_id],
        },
      )
    end
  end
end
