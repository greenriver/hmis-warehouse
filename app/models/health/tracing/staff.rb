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

    def self.label_for(column_name)
      @label_for ||= {
        first_name: 'First name',
        last_name: 'Last name',
        site_name: 'Site name',
        notified: 'Notified?',
        nature_of_exposure: 'Nature of exposure',
        symptomatic: 'Symptomatic?',
        referred_for_testing: 'Referred for testing?',
        test_result: 'Test result',
        notes: '',
      }
      @label_for[column_name]
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end

