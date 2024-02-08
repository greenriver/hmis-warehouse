###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::Enrollment, type: :model do
  let!(:ds1) { create :hmis_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:rrh) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 13 }
  let!(:nbn) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 1  }

  def expect_validations(enrollment, expected_errors:, context:)
    enrollment.valid?([:form_submission, context])
    errors = enrollment.errors.map { |e| [e.type, e.options[:attribute_override] || e.attribute] }
    expect(errors).to contain_exactly(*expected_errors)
  end

  it 'shouldn\'t validate MCI fields if MCI credential is not present' do
    client = build(:hmis_hud_client, data_source: ds1, first_name: nil, dob: nil)
    en = build(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
    expect_validations(en, expected_errors: [], context: :new_client_enrollment_form)
  end

  describe 'AC Enrollment validation' do
    let!(:mci_cred) { create(:ac_hmis_mci_credential) }
    let(:first_last_required) do
      [
        [:required, :first_name],
        [:required, :last_name],
      ]
    end

    let(:all_fields_and_mci_required) do
      [
        *first_last_required,
        [:invalid, :name_data_quality],
        [:required, :dob],
        [:invalid, :dob_data_quality],
        [:required, :mci_id],
      ]
    end

    describe 'should validate when enrolling an EXISTING client' do
      let(:client) { create(:hmis_hud_client, data_source: ds1, first_name: nil, last_name: nil, dob: nil, name_data_quality: 8, dob_data_quality: 9) }

      it 'in RRH project (only validate presence of MCI, not individual name fields)' do
        en = build(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
        expect_validations(en, expected_errors: [[:required, :mci_id]], context: :enrollment_form)
      end

      it 'in ES NBN project (no validations, MCI not required)' do
        en = build(:hmis_hud_enrollment, data_source: ds1, project: nbn, client: client)
        expect_validations(en, expected_errors: [], context: :enrollment_form)
      end
    end

    describe 'should validate when enrolling a NEW client' do
      let(:client) { build(:hmis_hud_client, data_source: ds1, first_name: nil, last_name: nil, dob: nil, name_data_quality: 8, dob_data_quality: 9) }

      it 'in RRH project (all fields required, and clearance)' do
        en = build(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
        expect_validations(en, expected_errors: all_fields_and_mci_required, context: :new_client_enrollment_form)
      end

      it 'in ES NBN project (first/last required)' do
        en = build(:hmis_hud_enrollment, data_source: ds1, project: nbn, client: client)
        expect_validations(en, expected_errors: first_last_required, context: :new_client_enrollment_form)
      end
    end

    # When submitting any old enrollment form - like updating move in date - we should not validate MCI
    it 'should not perform any MCI validation outside of new_client_enrollment_form/enrollment_form contexts' do
      client = create(:hmis_hud_client, data_source: ds1, first_name: nil, dob: nil)
      en = create(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
      expect(en.valid?(:form_submission)).to eq(true)

      en = build(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
      expect(en.valid?(:form_submission)).to eq(true)
    end

    # MCI validation should only happen when enrolling a client, not updating an existing enrollment
    it 'should not perform any MCI validation on persisted Enrollment record' do
      client = create(:hmis_hud_client, data_source: ds1, first_name: nil, dob: nil)
      en = create(:hmis_hud_enrollment, data_source: ds1, project: rrh, client: client)
      expect_validations(en, expected_errors: [], context: :enrollment_form)
    end
  end
end
