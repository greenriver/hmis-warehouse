###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::MciClearanceMatch < Types::BaseObject
    include Types::HmisSchema::HasGender

    field :id, ID, null: false
    field :mci_id, String, null: false
    field :score, Integer, null: false
    field :existing_client_id, ID, 'ID of existing Client that has the same MCI ID', null: true

    # NOTE: not resolving client details as a GQL Client type because they may be
    # unpersisted and/or have different values from the persisted record.
    field :first_name, String, null: false
    field :middle_name, String, null: true
    field :last_name, String, null: false
    field :name_suffix, String, null: true
    field :dob, GraphQL::Types::ISO8601Date, null: false
    field :age, Int, null: false
    field :ssn, String, null: true
    gender_field client_association: :client

    # object is a HmisExternalApis::MciClearanceResult

    # set an id for apollo
    def id
      object.mci_id
    end

    [:first_name, :middle_name, :last_name, :name_suffix, :dob, :ssn, :age].each do |attr|
      define_method(attr) do
        object.client.send(attr)
      end
    end
  end
end
