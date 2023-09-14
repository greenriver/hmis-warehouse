###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::Client, type: :model do
  let!(:ds1) { create :hmis_data_source }

  def expect_validations(client, expected_errors:, context:)
    client.valid?(context)
    errors = client.errors.map { |e| [e.type, e.options[:attribute_override] || e.attribute] }
    expect(errors).to contain_exactly(*expected_errors)
  end

  it 'shouldn\'t validate MCI fields if MCI credential is not present' do
    client = build(:hmis_hud_client, data_source: ds1, first_name: nil, dob: nil)
    expect_validations(client, expected_errors: [], context: :client_form)
    expect_validations(client, expected_errors: [], context: :new_client_enrollment_form)
  end

  describe 'AC client validation' do
    let!(:mci_cred) { create(:ac_hmis_mci_credential) }
    let(:c1) {  create(:hmis_hud_client, data_source: ds1, first_name: nil, last_name: nil, dob: nil, name_data_quality: 8, dob_data_quality: 9) }
    let(:c2) {  build(:hmis_hud_client, data_source: ds1, first_name: nil, last_name: nil, dob: nil, name_data_quality: 8, dob_data_quality: 9) }

    FIRST_LAST = [
      [:required, :first_name],
      [:required, :last_name],
    ].freeze

    ALL_MCI_FIELDS = [
      *FIRST_LAST,
      [:invalid, :name_data_quality],
      [:required, :dob],
      [:invalid, :dob_data_quality],
    ].freeze

    it 'should require all MCI fields on client form' do
      expected = [*ALL_MCI_FIELDS, [:required, :mci_id]]
      expect_validations(c1, expected_errors: expected, context: :client_form)
      expect_validations(c2, expected_errors: expected, context: :client_form)
    end

    it 'should require first/last on new client enrollment form' do
      expect_validations(c1, expected_errors: FIRST_LAST, context: :new_client_enrollment_form)
      expect_validations(c2, expected_errors: FIRST_LAST, context: :new_client_enrollment_form)
    end

    it 'should accept primary name in names array as valid first/last' do
      c2.names = [build(:hmis_hud_custom_client_name, data_source: ds1, client: c2, primary: true)]
      expect_validations(c2, expected_errors: [], context: :new_client_enrollment_form)
    end

    it 'should accept name fields as valid first/last' do
      c2.first_name = 'first'
      c2.last_name = 'last'
      expect_validations(c2, expected_errors: [], context: :new_client_enrollment_form)
    end

    it 'should require MCI fields on new client enrollment form if extra context is included' do
      # Note: doesn't validate MCI ID field. That happens on Enrollment because the client doesn't know which project
      # that it's being created in.
      expect_validations(c1, expected_errors: ALL_MCI_FIELDS, context: [:new_client_enrollment_form, :enrollment_requiring_mci])
      expect_validations(c2, expected_errors: ALL_MCI_FIELDS, context: [:new_client_enrollment_form, :enrollment_requiring_mci])
    end
  end
end
