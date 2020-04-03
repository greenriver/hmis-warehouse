###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Contact < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :case
    has_many :locations

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

    def yes_no_options
      [
        'No',
        'Yes',
      ]
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end