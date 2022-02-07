###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Cas
  class Tag < CasBase
    acts_as_paranoid

    def self.available_cohort_tags
      where(rrh_assessment_trigger: false)
    end

    def self.available_tags
      all
    end
  end
end
