# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Enrollment, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:project) { create(:hud_project, data_source: data_source, organization: organization) }
  let(:client) { create(:hud_client, data_source: data_source) }
  let(:hud_enrollment) do
    create(:hud_enrollment, client: client, project: project, data_source: data_source, entry_date: report_start_date + 1.day)
  end
  let(:report) { create_report([project]) }

  describe '.from_hud_record' do
    context 'with income_benefits records' do
      context 'with multiple income_benefit records' do
        let!(:older_income_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            information_date: report_start_date + 5.days,
            Medicaid: 1,
            Earned: 0,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        let!(:latest_income_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            information_date: report_start_date + 15.days,
            Medicaid: 0,
            Medicare: 1,
            Earned: 1,
            SSDI: 1,
            IncomeFromAnySource: 1,
            InsuranceFromAnySource: 1,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        let!(:middle_income_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            information_date: report_start_date + 10.days,
            Medicaid: 1,
            Medicare: 1,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'uses only the latest income_benefit record as of report end date' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          # Should use latest_income_benefit values only
          expect(enrollment.medical_insurance_types).to contain_exactly('Medicare', 'InsuranceFromAnySource')
          expect(enrollment.income_benefit_source_types).to contain_exactly('Earned', 'SSDI', 'IncomeFromAnySource')
          expect(enrollment.medical_insurance_types).not_to include('Medicaid')
        end
      end

      context 'with income_benefit dated after report end_date' do
        let!(:within_range_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            information_date: report_end_date - 1.day,
            Medicaid: 1,
            Earned: 1,
            IncomeFromAnySource: 1,
            InsuranceFromAnySource: 1,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        let!(:after_report_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            information_date: report_end_date + 10.days,
            Medicare: 1,
            SSDI: 1,
            IncomeFromAnySource: 1,
            InsuranceFromAnySource: 1,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'ignores income_benefit records dated after report end_date' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          # Should only use within_range_benefit
          expect(enrollment.medical_insurance_types).to contain_exactly('Medicaid', 'InsuranceFromAnySource')
          expect(enrollment.income_benefit_source_types).to contain_exactly('Earned', 'IncomeFromAnySource')
          expect(enrollment.medical_insurance_types).not_to include('Medicare')
          expect(enrollment.income_benefit_source_types).not_to include('SSDI')
        end
      end

      context 'with explicit "No" for income and insurance' do
        let!(:no_income_benefit) do
          create(
            :hud_income_benefit,
            enrollment: hud_enrollment,
            IncomeFromAnySource: 0,
            InsuranceFromAnySource: 0,
            information_date: report_start_date + 5.days,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'adds "No" markers to the arrays' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.medical_insurance_types).to contain_exactly('NoInsuranceSource')
          expect(enrollment.income_benefit_source_types).to contain_exactly('NoIncomeSource')
        end
      end

      context 'with no income_benefit records at all' do
        it 'handles missing income_benefits gracefully with empty arrays' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.medical_insurance_types).to be_empty
          expect(enrollment.income_benefit_source_types).to be_empty
        end
      end
    end

    context 'with HIV disability records' do
      context 'with disability_response set to 1' do
        let!(:confirmed_hiv_disability) do
          create(
            :hud_disability,
            enrollment: hud_enrollment,
            disability_type: hiv_positive,
            disability_response: 1,
            anti_retroviral: 1,
            viral_load_available: 1,
            viral_load: 150,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'marks enrollment as hiv_positive when disability_response is 1' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.hiv_positive).to be(true)
          expect(enrollment.viral_load_suppression).to be(true)
          expect(enrollment.ever_prescribed_anti_retroviral_therapy).to be(true)
        end
      end

      context 'with disability_response not set to 1' do
        let!(:unconfirmed_hiv_disability) do
          create(
            :hud_disability,
            enrollment: hud_enrollment,
            disability_type: hiv_positive,
            disability_response: 0,
            anti_retroviral: 1,
            viral_load_available: 1,
            viral_load: 150,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'does not mark enrollment as hiv_positive when disability_response is not 1' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.hiv_positive).to be(false)
          expect(enrollment.viral_load_suppression).to be(false)
          expect(enrollment.ever_prescribed_anti_retroviral_therapy).to be(false)
        end
      end

      context 'with mixed disability_response values' do
        let!(:confirmed_hiv) do
          create(
            :hud_disability,
            enrollment: hud_enrollment,
            disability_type: hiv_positive,
            disability_response: 1,
            anti_retroviral: 1,
            viral_load_available: 1,
            viral_load: 150,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        let!(:unconfirmed_hiv) do
          create(
            :hud_disability,
            enrollment: hud_enrollment,
            disability_type: hiv_positive,
            disability_response: 0,
            viral_load_available: 1,
            viral_load: 50,
            data_source: data_source,
            personal_id: client.PersonalID,
          )
        end

        it 'considers only confirmed disabilities for hiv_positive status' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.hiv_positive).to be(true)
          # Should use confirmed_hiv viral load (150), not unconfirmed (50)
          expect(enrollment.viral_load_suppression).to be(true)
        end
      end

      context 'with no HIV disabilities' do
        it 'marks enrollment as not hiv_positive' do
          enrollment = described_class.from_hud_record(
            enrollment: hud_enrollment,
            report: report,
            client: client,
          )

          expect(enrollment.hiv_positive).to be(false)
          expect(enrollment.viral_load_suppression).to be(false)
          expect(enrollment.ever_prescribed_anti_retroviral_therapy).to be(false)
        end
      end
    end
  end

  describe '#hmis_enrollment_id' do
    it 'returns enrollment_id from underlying record' do
      enrollment = described_class.new(enrollment: hud_enrollment)
      expect(enrollment.hmis_enrollment_id).to eq(hud_enrollment.enrollment_id)
    end
  end
end
