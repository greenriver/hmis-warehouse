###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::WorkspaceAppliesTo < Types::BaseEnum
    value 'CE_REFERRALS', 'CE referrals workspace switcher', value: Hmis::Workspace::CE_REFERRALS
  end
end
