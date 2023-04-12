###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteClient < BaseMutation
    argument :id, ID, required: true
    argument :confirm, Boolean, required: false

    field :client, Types::HmisSchema::Client, null: true

    def resolve(id:, _confirm: false)
      client = Hmis::Hud::Client.find_by(id: id)

      # enrollments = client.enrollments

      default_delete_record(
        record: client,
        field_name: :client,
        permissions: :can_delete_clients,
      )
    end
  end
end
