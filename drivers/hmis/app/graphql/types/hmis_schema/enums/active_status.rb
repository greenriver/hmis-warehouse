###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ActiveStatus < Types::BaseEnum
    value 'ACTIVE', 'Active'
    value 'INACTIVE', 'Inactive'
  end
end
