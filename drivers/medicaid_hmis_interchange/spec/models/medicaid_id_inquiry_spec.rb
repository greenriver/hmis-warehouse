###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MedicaidHmisInterchange::Health::MedicaidIdInquiry, type: :model do
  before do
    Health::Cp.destroy_all
  end

  let!(:sender) { create :sender }
  let!(:client_1) do
    create(
      :grda_warehouse_hud_client,
      FirstName: 'John',
      LastName: 'Doe',
      MiddleName: 'M',
      DOB: Date.new(1990, 1, 1),
      SSN: '123456789',
      Woman: 1,
    )
  end
  let!(:client_2) do
    create(
      :grda_warehouse_hud_client,
      FirstName: 'Jane',
      LastName: 'Smith',
      MiddleName: nil,
      DOB: Date.new(1985, 5, 15),
      SSN: '987654321',
      Man: 1,
    )
  end
  let(:inquiry) { build :mhx_medicaid_id_inquiry, service_date: Date.current }

  before(:each) do
    inquiry.clients = [client_1, client_2]
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
      expect(edi_text).to include('TRN')
      expect(edi_text).to include('DMG')
      expect(edi_text).to include('DTP')
      expect(edi_text).to include('EQ')
      expect(edi_text).to include('SE')
      expect(edi_text).to include('GE')
      expect(edi_text).to include('IEA')
    end

    it 'includes client names in the EDI file' do
      inquiry.build_inquiry_file
      edi_text = inquiry.inquiry

      expect(edi_text).to include(client_1.LastName.upcase)
      expect(edi_text).to include(client_1.FirstName.upcase)
      expect(edi_text).to include(client_2.LastName.upcase)
      expect(edi_text).to include(client_2.FirstName.upcase)
    end

    it 'does not raise frozen string literal errors' do
      expect { inquiry.build_inquiry_file }.not_to raise_error
    end
  end

  describe 'control number assignment' do
    it 'assigns control numbers when saved' do
      inquiry.build_inquiry_file
      inquiry.save!

      expect(inquiry.isa_control_number).to be_present
      expect(inquiry.group_control_number).to be_present
      expect(inquiry.transaction_control_number).to be_present
    end

    it 'increments control numbers for subsequent inquiries' do
      inquiry.build_inquiry_file
      inquiry.save!

      inquiry2 = build(:mhx_medicaid_id_inquiry, service_date: Date.current)
      inquiry2.clients = [client_1]
      inquiry2.build_inquiry_file
      inquiry2.save!

      expect(inquiry2.isa_control_number).to be > inquiry.isa_control_number
      expect(inquiry2.group_control_number).to be > inquiry.group_control_number
      expect(inquiry2.transaction_control_number).to be > inquiry.transaction_control_number
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

  describe 'client filtering' do
    let(:filtering_inquiry) { build :mhx_medicaid_id_inquiry, service_date: Date.current }

    it 'skips clients without DOB and SSN' do
      client_without_identifiers = create(
        :grda_warehouse_hud_client,
        FirstName: 'Missing',
        LastName: 'Data',
        DOB: nil,
        SSN: nil,
      )
      filtering_inquiry.clients = [client_without_identifiers, client_1]
      filtering_inquiry.build_inquiry_file

      expect(filtering_inquiry.inquiry).not_to include('MISSING')
      expect(filtering_inquiry.inquiry).to include('JOHN')
    end

    it 'skips clients without names' do
      client_without_name = create(
        :grda_warehouse_hud_client,
        FirstName: nil,
        LastName: nil,
        DOB: Date.new(1990, 1, 1),
        SSN: '111111111',
      )
      filtering_inquiry.clients = [client_without_name, client_1]
      filtering_inquiry.build_inquiry_file

      expect(filtering_inquiry.inquiry).not_to include('111111111')
      expect(filtering_inquiry.inquiry).to include('JOHN')
    end
  end
end
