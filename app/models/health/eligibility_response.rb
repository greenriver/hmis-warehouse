# ### HIPAA Risk Assessment
# Risk:
# Control:

require "stupidedi"
module Health
  class EligibilityResponse < HealthBase

    belongs_to :eligibility_inquiry, class_name: Health::EligibilityInquiry

  end
end
