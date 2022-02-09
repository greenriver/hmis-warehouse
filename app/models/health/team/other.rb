###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented in base class
module Health
  class Team::Other < Team::Member

    validates_presence_of :title
    def self.member_type_name
      'Other Important Contact'
    end

    def full_name
      "#{first_name} #{last_name} (#{title})"
    end
  end
end
