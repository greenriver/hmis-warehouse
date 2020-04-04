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
      {
        'Unknown' => '',
        'No' => 'No',
        'Yes' => 'Yes',
      }
    end

    def referred_options
      yes_no_options
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
      }
    end

    def test_result_options
      {
        'Unknown' => '',
        'Negative' => 'Negative',
        'Positive' => 'Positive',
      }
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end

