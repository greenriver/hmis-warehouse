###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ClientMergeCandidate < Types::BaseObject
    field :id, ID, null: false, description: 'Warehouse ID'
    field :warehouse_url, String, null: false
    field :clients, [HmisSchema::Client], null: false

    # object is a Hmis::Hud::Client that is a "destination client"

    def clients
      load_ar_association(object, :source_clients).select do |client|
        client.data_source_id == current_user.hmis_data_source_id
      end
    end

    def warehouse_url
      "https://#{ENV['FQDN']}/clients/#{object.id}"
    end
  end
end
