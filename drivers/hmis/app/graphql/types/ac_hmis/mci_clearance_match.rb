###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::MciClearanceMatch < Types::BaseObject
    field :id, ID, null: false
    field :mci_id, String, null: false
    field :score, Integer, null: false
    field :existing_client_id, ID, 'ID of existing Client that has the same MCI ID', null: true

    # Client details
    field :first_name, String, null: false
    field :middle_name, String, null: true
    field :last_name, String, null: false
    field :name_suffix, String, null: true
    field :dob, GraphQL::Types::ISO8601Date, null: false
    field :age, Int, null: false
    field :ssn, String, null: true
    field :gender, [Types::HmisSchema::Enums::Gender], null: false
    field :race, [Types::HmisSchema::Enums::Race], null: false

    def self.from_mci_clearance_result(result)
      client_fields = [:first_name, :middle_name, :last_name, :name_suffix, :dob, :ssn].map { |key| [key, result.client.send(key)] }.to_h
      {
        id: result.mci_id.to_i,
        mci_id: result.mci_id,
        score: result.score,
        existing_client_id: result.existing_client_id,
        **client_fields,
        # TODO age, race, gender
      }
    end
  end
end
