###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::DataCollectedAbout < Types::BaseEnum
    graphql_name 'DataCollectedAbout'

    value 'ALL_CLIENTS'
    value 'HOH_AND_ADULTS'
    value 'HOH'
    value 'ALL_VETERANS'
    value 'ALL_CLIENTS_RECEIVING_SSVF_SERVICES'
    value 'ALL_CLIENTS_RECEIVING_SSVF_FINANCIAL_ASSISTANCE'
    value 'VETERAN_HOH'
  end
end
