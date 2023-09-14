###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::Client, type: :model do
  let!(:ds1) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:rrh) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 13 }
  let!(:nbn) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 1  }

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
    # persisted
    let(:c1) do
      client = create(:hmis_hud_client, data_source: ds1, dob: nil, dob_data_quality: 8)
      name = create(:hmis_hud_custom_client_name, client: client, data_source: ds1, last: nil, name_data_quality: 8, primary: true)
      client.names = [name]
      client.save!
      client
    end
    # unpersisted
    let(:c2) do
      client = build(:hmis_hud_client, data_source: ds1, dob: nil, dob_data_quality: 8)
      name = build(:hmis_hud_custom_client_name, client: client, data_source: ds1, last: nil, name_data_quality: 8, primary: true)
      client.names = [name]
      client
    end

    FIRST_LAST = [
      # Examples all have a first name, so that we don't hit the "first or last required" err
      # [:required, :first_name],
      [:required, :last_name],
    ].freeze

    ALL_MCI_FIELDS = [
      *FIRST_LAST,
      [:invalid, :name_data_quality],
      [:required, :dob],
      [:invalid, :dob_data_quality],
    ].freeze

    describe 'when submitting Client Form' do
      it 'should require all MCI fields (new client)' do
        expected = [*ALL_MCI_FIELDS, [:required, :mci_id]]
        expect_validations(c2, expected_errors: expected, context: :client_form)
      end

      it 'should require all MCI fields (persisted client with no enrollments)' do
        expected = [*ALL_MCI_FIELDS, [:required, :mci_id]]
        expect_validations(c1, expected_errors: expected, context: :client_form)
      end

      it 'should not require MCI fields (persisted client with only NBN enrollments)' do
        create(:hmis_hud_enrollment, data_source: ds1, project: nbn, client: c1)
        expect_validations(c1, expected_errors: FIRST_LAST, context: :client_form)
      end

      it 'should require MCI fields (persisted client with only NBN enrollments that has already been cleared)' do
        expected = [*ALL_MCI_FIELDS, [:required, :mci_id]]
        c1.create_mci_id = true
        create(:hmis_hud_enrollment, data_source: ds1, project: nbn, client: c1)
        expect_validations(c2, expected_errors: expected, context: :client_form)
      end

      it 'should require MCI fields (persisted client with NBN & RRH enrollments)' do
        expected = [*ALL_MCI_FIELDS, [:required, :mci_id]]
        create(:hmis_hud_enrollment, data_source: ds1, project: nbn, client: c1)
        create(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: c1)
        expect_validations(c2, expected_errors: expected, context: :client_form)
      end
    end

    it 'should require first/last on new client enrollment form' do
      expect_validations(c1, expected_errors: FIRST_LAST, context: :new_client_enrollment_form)
      expect_validations(c2, expected_errors: FIRST_LAST, context: :new_client_enrollment_form)
    end

    it 'should accept primary name in names array as valid first/last' do
      c2.names = [build(:hmis_hud_custom_client_name, data_source: ds1, client: c2, primary: true)]
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
