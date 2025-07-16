###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectConfigInput < BaseInputObject
    description 'Project Config Input'

    argument :config_type, HmisSchema::Enums::ProjectConfigType, required: false
    argument :length_of_absence_days, Int, required: false
    argument :accepts_direct_referrals, Boolean, required: false
    # accepts_direct_referrals_from not yet supported in the UI (requires multi-select project dropdown)
    argument :supports_waitlist_referrals, Boolean, required: false
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :project_id, ID, required: false
    argument :organization_id, ID, required: false

    def to_params
      to_h.except!(:config_type)
    end
  end
end
