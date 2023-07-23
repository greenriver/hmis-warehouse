###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ExternalIdentifierType < Types::BaseEnum
    description 'External Identifier Type'
    graphql_name 'ExternalIdentifierType'

    value 'CLIENT_ID', value: :client_id, description: 'HMIS ID'
    value 'PERSONAL_ID', value: :personal_id, description: 'Personal ID'
    value 'WAREHOUSE_ID', value: :warehouse_id, description: 'Warehouse ID'
    value 'MCI_ID', value: :mci_id, description: 'MCI ID'
  end
end
