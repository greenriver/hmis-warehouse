###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class ParticipationFormFile < Health::HealthFile

    belongs_to :participation_form, class_name: 'Health::ParticipationForm', foreign_key: :parent_id, optional: true

    def title
      'Participation Form'
    end
  end
end
