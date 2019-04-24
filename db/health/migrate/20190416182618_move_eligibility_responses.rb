class MoveEligibilityResponses < ActiveRecord::Migration
  def up
    Health::EligibilityInquiry.find_each do |inquiry|
      Health::EligibilityResponse.create(eligibility_inquiry: inquiry, response: inquiry.result)
    end
  end

  def down
    Health::EligibilityResponse.find_each do |response|
      Health::EligibilityInquiry.find(response.eligibility_inquiry).update(result: response.response)
    end
  end
end
