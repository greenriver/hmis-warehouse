###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::HudDataCollectionGapAnalyzer::DataPresenceScanner do
  subject(:scanner) { described_class.new(project: project, date_range: date_range) }

  let(:date_range) { Date.new(2025, 1, 1)..Date.new(2025, 12, 31) }
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:project) { create(:hud_project, data_source_id: data_source.id, ProjectType: 1) }
  let(:other_project) { create(:hud_project, data_source_id: data_source.id, ProjectType: 1) }
  let(:enrollment) do
    create(:hud_enrollment, data_source_id: data_source.id, ProjectID: project.ProjectID)
  end
  let(:other_enrollment) do
    create(:hud_enrollment, data_source_id: data_source.id, ProjectID: other_project.ProjectID)
  end

  let(:registry) { HmisUtil::HudDataCollectionGapAnalyzer::ElementRegistry.new }
  def element_for(field_name)
    registry.assessment_elements.find { |e| e.field_name == field_name }
  end

  def income_benefit(attrs)
    create(
      :hud_income_benefit,
      { data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID }.merge(attrs),
    )
  end

  describe '#field_presence for a coded element' do
    let(:element) { element_for('incomeFromAnySource') }

    it 'counts 8 and 9 as real data but not 99 or nil' do
      income_benefit(InformationDate: Date.new(2025, 3, 1), IncomeFromAnySource: 8)
      income_benefit(InformationDate: Date.new(2025, 6, 1), IncomeFromAnySource: 9)
      income_benefit(InformationDate: Date.new(2025, 7, 1), IncomeFromAnySource: 99)
      income_benefit(InformationDate: Date.new(2025, 8, 1), IncomeFromAnySource: nil)

      expect(scanner.field_presence(element)).to have_attributes(
        count: 2,
        earliest: Date.new(2025, 3, 1),
        latest: Date.new(2025, 6, 1),
      )
    end

    it 'excludes records reached through another project\'s enrollments' do
      create(
        :hud_income_benefit,
        data_source_id: data_source.id,
        EnrollmentID: other_enrollment.EnrollmentID,
        PersonalID: other_enrollment.PersonalID,
        InformationDate: Date.new(2025, 3, 1),
        IncomeFromAnySource: 1,
      )

      expect(scanner.field_presence(element).count).to eq(0)
    end

    it 'excludes records outside the date range' do
      income_benefit(InformationDate: Date.new(2024, 12, 31), IncomeFromAnySource: 1)
      income_benefit(InformationDate: Date.new(2026, 1, 1), IncomeFromAnySource: 1)
      income_benefit(InformationDate: Date.new(2025, 1, 1), IncomeFromAnySource: 1)

      expect(scanner.field_presence(element).count).to eq(1)
    end
  end

  describe '#field_presence for a currency element' do
    let(:element) { element_for('earnedAmount') }

    it 'counts 99 as a real amount' do
      income_benefit(InformationDate: Date.new(2025, 3, 1), EarnedAmount: 99)
      income_benefit(InformationDate: Date.new(2025, 4, 1), EarnedAmount: nil)

      expect(scanner.field_presence(element).count).to eq(1)
    end
  end

  describe '#field_presence for a disability element' do
    let(:element) { element_for('physicalDisability') }

    def disability(attrs)
      create(
        :hud_disability,
        { data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID }.merge(attrs),
      )
    end

    it 'counts only rows of the matching DisabilityType' do
      disability(InformationDate: Date.new(2025, 3, 1), DisabilityType: 5, DisabilityResponse: 1)
      # Mental health disorder row with a real response must not be attributed to physical.
      disability(InformationDate: Date.new(2025, 4, 1), DisabilityType: 9, DisabilityResponse: 1)

      expect(scanner.field_presence(element)).to have_attributes(count: 1, earliest: Date.new(2025, 3, 1))
    end

    it 'reads IndefiniteAndImpairs for the A-variant element rather than DisabilityResponse' do
      disability(
        InformationDate: Date.new(2025, 3, 1),
        DisabilityType: 5,
        DisabilityResponse: 1,
        IndefiniteAndImpairs: nil,
      )

      variant = element_for('physicalDisabilityIndefiniteAndImpairs')

      expect(scanner.field_presence(variant).count).to eq(0)
    end
  end

  describe '#service_presence_by_record_type' do
    def service(attrs)
      create(
        :hud_service,
        { data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID }.merge(attrs),
      )
    end

    it 'groups by RecordType and uses DateProvided as the date column' do
      bed_night = HudHelper.util.record_type('Bed Night', true, raise_on_missing: true)
      path_service = HudHelper.util.record_type('PATH Service', true, raise_on_missing: true)
      service(DateProvided: Date.new(2025, 2, 1), RecordType: bed_night)
      service(DateProvided: Date.new(2025, 5, 1), RecordType: bed_night)
      service(DateProvided: Date.new(2025, 3, 1), RecordType: path_service)

      result = scanner.service_presence_by_record_type

      expect(result[bed_night]).to have_attributes(
        count: 2,
        earliest: Date.new(2025, 2, 1),
        latest: Date.new(2025, 5, 1),
      )
      expect(result[path_service].count).to eq(1)
    end
  end

  describe '#table_presence' do
    it 'counts current living situations for this project within the range' do
      create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: Date.new(2025, 4, 1),
      )
      create(
        :hud_current_living_situation,
        data_source_id: data_source.id,
        EnrollmentID: other_enrollment.EnrollmentID,
        PersonalID: other_enrollment.PersonalID,
        InformationDate: Date.new(2025, 4, 1),
      )

      expect(scanner.table_presence(:current_living_situations)).to have_attributes(
        count: 1,
        earliest: Date.new(2025, 4, 1),
      )
    end
  end
end
