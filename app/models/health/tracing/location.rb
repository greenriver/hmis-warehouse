###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Location < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case
  end
end
