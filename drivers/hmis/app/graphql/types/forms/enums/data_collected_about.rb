###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::DataCollectedAbout < Types::BaseEnum
    graphql_name 'DataCollectedAbout'

    [
      'ALL_CLIENTS',
      'HOH_AND_ADULTS',
      'HOH',
      'ALL_VETERANS',
      'ALL_CLIENTS_RECEIVING_SSVF_SERVICES',
      'ALL_CLIENTS_RECEIVING_SSVF_FINANCIAL_ASSISTANCE',
      'VETERAN_HOH',
    ].each do |val|
      description = val.titleize.
        gsub(/\bHoh\b/, 'HoH').
        gsub(/\bSsvf\b/, 'SSVF').
        gsub(/\bAnd\b/, 'and')
      value val, description, value: val
    end
  end
end
