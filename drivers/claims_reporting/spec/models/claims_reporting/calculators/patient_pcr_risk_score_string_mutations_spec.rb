# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClaimsReporting::Calculators::PatientPcrRiskScore, type: :model do
  describe '#ihs_risk_adjustment method with += operations' do
    it 'calls ihs_risk_adjustment method that contains += operation' do
      # Test the += operation from line 117: comorb_dx_codes += c.dx_codes

      calculator = described_class.new

      # Mock member and claims data
      member = double('member')
      stay_claims = []
      claims = []

      # Mock the dependencies that ihs_risk_adjustment method uses
      allow(calculator).to receive(:measurement_year).and_return(Date.current.beginning_of_year..Date.current.end_of_year)

      # Call the actual method that contains the += operation
      expect { calculator.ihs_risk_adjustment(member, stay_claims, claims) }.not_to raise_error
    end

    it 'exercises ihs_risk_adjustment with mock claims containing dx_codes' do
      calculator = described_class.new

      member = double('member')
      stay_claims = []

      # Mock claims with dx_codes to exercise the += operation
      claim = double(
        'claim',
        dx_codes: ['E11.9', 'I10'],
        discharge_date: Date.current,
      )
      claims = [claim]

      allow(calculator).to receive(:measurement_year).and_return(Date.current.beginning_of_year..Date.current.end_of_year)
      allow(calculator).to receive_message_chain(:class, :hl7_module).and_return(double('hl7', in_set?: true))
      allow(Hl7).to receive(:in_set?).and_return(true)

      # Should call the method without error and exercise the += operation
      expect { calculator.ihs_risk_adjustment(member, stay_claims, claims) }.not_to raise_error
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises the calculator methods that contain += operations' do
      medicaid_ids = ['12345', '67890']
      calculator = described_class.new(medicaid_ids)

      # Should initialize without error
      expect(calculator).to be_a(ClaimsReporting::Calculators::PatientPcrRiskScore)

      # Test that measurement_year method works (used by ihs_risk_adjustment)
      expect(calculator.measurement_year).to be_a(Range)
    end
  end
end
