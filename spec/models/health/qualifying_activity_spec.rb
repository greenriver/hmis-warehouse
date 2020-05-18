require 'rails_helper'

RSpec.describe Health::QualifyingActivity, type: :model do
  describe 'with single referral' do
    let(:pre_enrollment_activity) { create :qualifying_activity, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be false
      expect(qualifying_activity.naturally_payable).to be true
    end
  end

  describe 'with multiple referrals' do
    let(:pre_enrollment_activity) { create :qualifying_activity_for_patient_a, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity_for_patient_a }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be false
      expect(qualifying_activity.naturally_payable).to be true
    end
  end
end
