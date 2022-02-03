###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health::ChaTools
  class ChaSource
    def each
      Health::ComprehensiveHealthAssessment.completed.find_each do |cha|
        yield cha.as_interchange
      end
    end
  end
end
