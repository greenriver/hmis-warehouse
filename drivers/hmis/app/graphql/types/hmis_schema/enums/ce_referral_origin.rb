###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeReferralOrigin < Types::BaseEnum
    value 'direct_send', 'Direct'
    value 'waitlist', 'Waitlist'
  end
end
