###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HealthComprehensiveAssessment
  class Medication < HealthBase
    belongs_to :assessment
  end
end
