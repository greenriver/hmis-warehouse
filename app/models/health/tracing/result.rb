###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: ?
# Control: PHI attributes NOT documented
module Health::Tracing
  class Result < HealthBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :contact

    def test_result_options
      {
        'Unknown' => '',
        'Negative' => 'Negative',
        'Positive' => 'Positive',
      }
    end

    def yes_no_options
      {
        'No' => '',
        'Yes' => 'Yes',
        'Declined' => 'Declined',
      }
    end

    def self.label_for(column_name)
      @label_for ||= {
        test_result: 'Test result',
        isolated: 'Went to Isolation?',
        isolation_location: 'Isolation location',
        quarantine: 'Went to Quarantine?',
        quarantine_location: 'Quarantine location',
      }
      @label_for[column_name]
    end

    def label_for(column_name)
      self.class.label_for(column_name)
    end
  end
end
