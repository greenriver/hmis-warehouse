###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class SdhCaseManagementNoteFile < Health::HealthFile

    belongs_to :sdh_case_management_note, class_name: 'Health::SdhCaseManagementNote', foreign_key: :parent_id, optional: true

  end
end
