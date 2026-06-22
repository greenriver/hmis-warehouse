###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::SystemStatus < Types::BaseEnum
    value 'SYSTEM', 'System'
    value 'NON_SYSTEM', 'Non-System'
  end
end
