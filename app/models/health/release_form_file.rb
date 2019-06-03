###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Indirectly relates to a patient. Binary data may contain PHI
# Control: PHI attributes documented in base class
module Health
  class ReleaseFormFile < Health::HealthFile

    belongs_to :release_form, class_name: 'Health::ReleaseForm', foreign_key: :parent_id

    def title
      'Release Form'
    end
  end
end