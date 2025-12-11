# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::EligibilityInquiry, type: :model do
  before(:all) do
    Health::Cp.destroy_all
  end

  let!(:sender) { create :sender }
  let!(:patient_1) { create :patient, medicaid_id: '123456789', first_name: 'John', last_name: 'Doe', middle_name: 'M', birthdate: Date.new(1990, 1, 1), gender: 'M' }
  let!(:patient_2) { create :patient, medicaid_id: '987654321', first_name: 'Jane', last_name: 'Smith', middle_name: nil, birthdate: Date.new(1985, 5, 15), gender: 'F' }
  let(:inquiry) { create :eligibility_inquiry, service_date: Date.current }

  before(:each) do
    inquiry.batch = [patient_1, patient_2]
    inquiry.save!
  end

  describe '#build_inquiry_file' do
    it 'generates inquiry text without errors' do
      expect { inquiry.build_inquiry_file }.not_to raise_error
    end

    it 'generates non-empty inquiry text' do
      inquiry.build_inquiry_file
      expect(inquiry.inquiry).to be_present
      expect(inquiry.inquiry.length).to be > 0
    end

    it 'generates EDI format with required segments' do
      inquiry.build_inquiry_file
      edi_text = inquiry.inquiry

      expect(edi_text).to include('ISA')
      expect(edi_text).to include('GS')
      expect(edi_text).to include('ST')
      expect(edi_text).to include('BHT')
      expect(edi_text).to include('HL')
      expect(edi_text).to include('NM1')
      expect(edi_text).to include('DMG')
      expect(edi_text).to include('DTP')
      expect(edi_text).to include('EQ')
      expect(edi_text).to include('SE')
      expect(edi_text).to include('GE')
      expect(edi_text).to include('IEA')
    end

    it 'includes patient medicaid IDs in the EDI file' do
      inquiry.build_inquiry_file
      edi_text = inquiry.inquiry

      expect(edi_text).to include(patient_1.medicaid_id)
      expect(edi_text).to include(patient_2.medicaid_id)
    end

    it 'includes patient names in the EDI file' do
      inquiry.build_inquiry_file
      edi_text = inquiry.inquiry

      expect(edi_text).to include(patient_1.last_name.upcase)
      expect(edi_text).to include(patient_1.first_name.upcase)
      expect(edi_text).to include(patient_2.last_name.upcase)
      expect(edi_text).to include(patient_2.first_name.upcase)
    end

    it 'does not raise frozen string literal warnings' do
      expect { inquiry.build_inquiry_file }.not_to raise_error
    end

    it 'sets control numbers when saved' do
      expect(inquiry.isa_control_number).to be_present
      expect(inquiry.group_control_number).to be_present
      expect(inquiry.transaction_control_number).to be_present
    end
  end

  describe '#build_inquiry_edi' do
    it 'builds EDI structure without errors' do
      expect { inquiry.send(:build_inquiry_edi) }.not_to raise_error
    end

    it 'sets @edi_builder instance variable' do
      inquiry.send(:build_inquiry_edi)
      expect(inquiry.instance_variable_get(:@edi_builder)).to be_present
    end
  end

  describe '#convert_to_text' do
    before do
      inquiry.send(:build_inquiry_edi)
    end

    it 'converts EDI builder to text without errors' do
      expect { inquiry.send(:convert_to_text) }.not_to raise_error
    end

    it 'returns a string' do
      result = inquiry.send(:convert_to_text)
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'generates uppercase EDI text' do
      result = inquiry.send(:convert_to_text)
      expect(result).to eq(result.upcase)
    end
  end
end
