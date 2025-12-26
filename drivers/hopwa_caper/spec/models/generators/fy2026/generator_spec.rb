# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Generators::Fy2026::Generator, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:tbra_funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:tbra_project) { create_hopwa_project(funder: tbra_funder) }
  let(:hoh_client_1) { create_client_with_warehouse_link }
  let(:hoh_client_2) { create_client_with_warehouse_link }
  let(:household_id_1) { Hmis::Hud::Base.generate_uuid }
  let(:household_id_2) { Hmis::Hud::Base.generate_uuid }

  let(:maintained_key) { 'maintained_contact_with_case_manager' }
  let(:housing_plan_key) { 'housing_plan' }
  let(:primary_health_key) { 'primary_health_contact' }

  let!(:maintained_definition) do
    create(:hmis_custom_data_element_definition, key: maintained_key, owner_type: 'Hmis::Hud::CustomAssessment')
  end

  let!(:housing_plan_definition) do
    create(:hmis_custom_data_element_definition, key: housing_plan_key, owner_type: 'Hmis::Hud::CustomAssessment')
  end

  let!(:primary_health_definition) do
    create(:hmis_custom_data_element_definition, key: primary_health_key, owner_type: 'Hmis::Hud::CustomAssessment')
  end

  let(:config_double) do
    instance_double(
      HopwaCaper::Configuration,
      atc_tab_enabled?: true,
      atc_maintained_contact_field_name: maintained_key,
      atc_housing_plan_field_name: housing_plan_key,
      atc_primary_health_contact_field_name: primary_health_key,
    )
  end

  before do
    allow(HopwaCaper::Configuration).to receive(:new).and_return(config_double)
  end

  describe '#populate_atc_data' do
    it 'successfully imports ATC data when enrollments have different data element sets (uniform hash keys)' do
      # Enrollment 1: Has ALL 3 fields populated in assessment
      enrollment_1 = create_hiv_positive_enrollment(
        client: hoh_client_1,
        project: tbra_project,
        entry_date: report_start_date + 1.day,
        household_id: household_id_1,
      )

      # Enrollment 2: Has Only 2 fields (missing primary_health_contact)
      enrollment_2 = create_hiv_positive_enrollment(
        client: hoh_client_2,
        project: tbra_project,
        entry_date: report_start_date + 1.day,
        household_id: household_id_2,
      )

      # Setup assessment data for enrollment 1 (ALL 3 fields)
      hmis_enrollment_1 = Hmis::Hud::Enrollment.find(enrollment_1.id)
      assessment_1 = create(:hmis_custom_assessment, data_source: data_source, enrollment: hmis_enrollment_1, client: hmis_enrollment_1.client)
      create(:hmis_custom_data_element, data_element_definition: maintained_definition, owner: assessment_1, value_string: 'Yes')
      create(:hmis_custom_data_element, data_element_definition: housing_plan_definition, owner: assessment_1, value_string: 'Yes')
      create(:hmis_custom_data_element, data_element_definition: primary_health_definition, owner: assessment_1, value_string: 'Yes')

      # Setup assessment data for enrollment 2 (Only 2 fields, missing primary_health_contact)
      hmis_enrollment_2 = Hmis::Hud::Enrollment.find(enrollment_2.id)
      assessment_2 = create(:hmis_custom_assessment, data_source: data_source, enrollment: hmis_enrollment_2, client: hmis_enrollment_2.client)
      create(:hmis_custom_data_element, data_element_definition: maintained_definition, owner: assessment_2, value_string: 'Yes')
      create(:hmis_custom_data_element, data_element_definition: housing_plan_definition, owner: assessment_2, value_string: 'Yes')

      report = create_report([tbra_project])

      # run_report helper triggers the generator workflow including populate_atc_data
      expect { run_report(report) }.not_to raise_error

      # Verify the data was actually imported
      report_enrollment_1 = report.hopwa_caper_enrollments.find_by(enrollment_id: enrollment_1.id)
      report_enrollment_2 = report.hopwa_caper_enrollments.find_by(enrollment_id: enrollment_2.id)

      expect(report_enrollment_2.atc_maintained_contact).to be(true)
      expect(report_enrollment_2.atc_housing_plan).to be(true)
      expect(report_enrollment_2.atc_primary_health_contact).to be_nil
    end

    it 'skips assessments with nil values and looks back to find a valid boolean answer' do
      enrollment = create_hiv_positive_enrollment(
        client: hoh_client_1,
        project: tbra_project,
        entry_date: report_start_date + 1.day,
        household_id: household_id_1,
      )

      hmis_enrollment = Hmis::Hud::Enrollment.find(enrollment.id)

      # Assessment 1: Older assessment with a valid "Yes" (True)
      assessment_old = create(
        :hmis_custom_assessment,
        data_source: data_source,
        enrollment: hmis_enrollment,
        client: hmis_enrollment.client,
        AssessmentDate: report_start_date + 5.days,
      )
      create(:hmis_custom_data_element, data_element_definition: maintained_definition, owner: assessment_old, value_string: 'Yes')

      # Assessment 2: Newer assessment with a NULL/nil value for the same field
      assessment_new = create(
        :hmis_custom_assessment,
        data_source: data_source,
        enrollment: hmis_enrollment,
        client: hmis_enrollment.client,
        AssessmentDate: report_start_date + 10.days,
      )
      # CDE exists but value_string is nil
      create(:hmis_custom_data_element, data_element_definition: maintained_definition, owner: assessment_new, value_string: nil)

      report = create_report([tbra_project])
      run_report(report)

      report_enrollment = report.hopwa_caper_enrollments.find_by(enrollment_id: enrollment.id)

      # Should have looked past the newer nil and found the older 'Yes'
      expect(report_enrollment.atc_maintained_contact).to be(true)
    end
  end

  describe '#update_hopwa_eligibility' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }

    it 'determines eligibility based on HIV status and HoH hierarchy' do
      # Case: HoH is NOT HIV+, but a child is. The child should be eligible.
      hoh = create_enrollment(
        client: hoh_client_1,
        project: tbra_project,
        entry_date: report_start_date,
        household_id: household_id,
        relationship_to_ho_h: 1,
      )
      child = create_hiv_positive_enrollment(
        client: hoh_client_2,
        project: tbra_project,
        entry_date: report_start_date,
        household_id: household_id,
        relationship_to_ho_h: 2,
      )

      report = create_report([tbra_project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.find_by(enrollment_id: hoh.id).hopwa_eligible).to be(false)
      expect(report.hopwa_caper_enrollments.find_by(enrollment_id: child.id).hopwa_eligible).to be(true)
    end
  end

  describe '#ensure_uniform_client_attrs' do
    it 'unifies HIV status and age across multiple enrollments for the same client' do
      # Client has two enrollments; one is HIV+, one is NOT
      create_enrollment(client: hoh_client_1, project: tbra_project, entry_date: report_start_date)
      create_hiv_positive_enrollment(
        client: hoh_client_1,
        project: tbra_project,
        entry_date: report_start_date + 1.month,
        household_id: Hmis::Hud::Base.generate_uuid,
      )

      report = create_report([tbra_project])
      run_report(report)

      # Both records should now be HIV+ in the report
      # We look up by destination_client_id because source clients are linked to it
      dest_client_id = GrdaWarehouse::Hud::Client.find(hoh_client_1.id).destination_client.id
      report_records = report.hopwa_caper_enrollments.where(destination_client_id: dest_client_id)
      expect(report_records.count).to eq(2)
      expect(report_records).to all(have_attributes(hiv_positive: true))
    end
  end

  describe '#cde_value_to_boolean' do
    let(:generator_instance) { described_class.new(create_report([tbra_project])) }
    let(:def_bool) { create(:hmis_custom_data_element_definition, field_type: 'boolean', owner_type: 'Hmis::Hud::CustomAssessment') }
    let(:def_int) { create(:hmis_custom_data_element_definition, field_type: 'integer', owner_type: 'Hmis::Hud::CustomAssessment') }
    let(:def_str) { create(:hmis_custom_data_element_definition, field_type: 'string', owner_type: 'Hmis::Hud::CustomAssessment') }

    it 'correctly casts various types and truthy/falsy values' do
      # Boolean
      expect(generator_instance.send(:cde_value_to_boolean, def_bool, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_boolean: true))).to be(true)
      expect(generator_instance.send(:cde_value_to_boolean, def_bool, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_boolean: nil))).to be_nil

      # Integer (Strict: 1=true, 0=false, others=nil)
      expect(generator_instance.send(:cde_value_to_boolean, def_int, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_integer: 1))).to be(true)
      expect(generator_instance.send(:cde_value_to_boolean, def_int, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_integer: 0))).to be(false)
      expect(generator_instance.send(:cde_value_to_boolean, def_int, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_integer: 8))).to be_nil
      expect(generator_instance.send(:cde_value_to_boolean, def_int, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_integer: 9))).to be_nil
      expect(generator_instance.send(:cde_value_to_boolean, def_int, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_integer: nil))).to be_nil

      # Strings (case-insensitive and support "yes"/"1")
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: 'Yes'))).to be(true)
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: '1'))).to be(true)
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: 'No'))).to be(false)
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: ''))).to be_nil
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: '  '))).to be_nil
      expect(generator_instance.send(:cde_value_to_boolean, def_str, build(:hmis_custom_data_element, owner_type: 'Hmis::Hud::CustomAssessment', value_string: nil))).to be_nil
    end
  end
end
