###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectConfigInput < BaseInputObject
    description 'Project Config Input'

    argument :config_type, HmisSchema::Enums::ProjectConfigType, required: false
    argument :length_of_absence_days, Int, required: false
    argument :receives_direct_referrals, Boolean, required: false
    # Allowlist of Project primary keys. Optional as a whole, so omitting it leaves any existing
    # allowlist alone and an explicit empty array clears it. Elements are non-null in the schema
    # ([ID!]) because the multi-select submits option codes, which are never null.
    argument :receives_direct_referrals_from, [ID], required: false
    argument :supports_waitlist_referrals, Boolean, required: false
    argument :project_type, Types::HmisSchema::Enums::ProjectType, required: false
    argument :project_id, ID, required: false
    argument :organization_id, ID, required: false

    def to_params
      to_h.except!(:config_type)
    end
  end
end
