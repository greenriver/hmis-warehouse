###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaData
  class ClientContact < GrdaWarehouseBase
    include Shared
    self.table_name = :eccovia_client_contacts
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
    acts_as_paranoid

    def self.fetch_updated(data_source_id:, credentials:, since:)
      since ||= default_lookback

      query = "crql?q=select ClientID, Address, Address2, City, State, ZipCode, ZipCodeID, HomePhone, WorkPhone, MsgPhone, Email, UpdatedDate from cmClient where UpdatedDate > '#{since.to_s(:db)}'"
      credentials.get_all_in_batches(query) do |client_batch|
        break unless client_batch.present?

        batch = client_batch.values.map do |client|
          new(
            data_source_id: data_source_id,
            client_id: client['ClientID'],
            street: client['Address'],
            street2: client['Address2'],
            city: client['City'],
            state: client['State'],
            zip: client['ZipCode'],
            email: client['Email'],
            phone: client['HomePhone'],
            cell_phone: client['MsgPhone'],
            last_fetched_at: Time.current,
          )
        end

        import(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id],
            columns: [:street, :street2, :city, :state, :zip, :email, :phone, :cell_phone, :last_fetched_at],
          },
          validate: false,
        )
      end
      remove_deleted(data_source_id: data_source_id, credentials: credentials)
    end

    def self.remove_deleted(data_source_id:, credentials:)
      where(data_source_id: data_source_id).where.not(client_id: all_client_ids(credentials: credentials)).destroy_all
    end

    def self.all_client_ids(credentials:)
      query = 'crql?q=select ClientID from cmClient'
      credentials.get_all(query)&.map { |a| a['ClientID'] }
    end
  end
end
