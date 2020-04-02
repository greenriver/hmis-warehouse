###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Staff < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case

    def symptomatic_options
      [
        'No',
        'Yes',
      ]
    end

    def referred_options
      [
        'No',
        'Yes',
      ]
    end

    def test_result_options
      [
        'Negative',
        'Positive',
      ]
    end
  end
end

