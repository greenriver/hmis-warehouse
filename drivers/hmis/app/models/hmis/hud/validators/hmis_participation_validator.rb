###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Hud::Validators::HmisParticipationValidator < Hmis::Hud::Validators::ParticipationValidator
  START_DATE_ATTRIBUTE = :HMISParticipationStatusStartDate
  END_DATE_ATTRIBUTE = :HMISParticipationStatusEndDate
end
