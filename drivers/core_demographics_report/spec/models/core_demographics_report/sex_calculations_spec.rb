###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'

RSpec.describe CoreDemographicsReport::SexCalculations, type: :model do
  include_context 'HUD enrollment builders'

  let(:user) { create(:user) }
  let(:project) { create_project(project_type: 1) }
  let(:report_date) { Date.current }
  let(:filter) do
    ::Filters::FilterBase.new(
      user: user,
      start: report_date.beginning_of_year,
      end: report_date.end_of_year,
      project_type_codes: HudHelper.util.homeless_project_type_codes,
      enforce_one_year_range: false,
      require_service_during_range: true,
    )
  end
  let(:report) { CoreDemographicsReport::Core.new(filter) }

  before do
    user.add_viewable(project)
  end

  describe '#sex_count' do
    let!(:client_female) { create_client_with_warehouse_link }
    let!(:client_male) { create_client_with_warehouse_link }
    let!(:client_unknown) { create_client_with_warehouse_link }
    let!(:client_nil) { create_client_with_warehouse_link }

    before do
      client_female.warehouse_client_source.destination.update(Sex: 0)
      client_male.warehouse_client_source.destination.update(Sex: 1)
      client_unknown.warehouse_client_source.destination.update(Sex: 8)
      client_nil.warehouse_client_source.destination.update(Sex: nil)

      enrollment_female = create_enrollment(client: client_female, project: project, entry_date: report_date)
      enrollment_male = create_enrollment(client: client_male, project: project, entry_date: report_date)
      enrollment_unknown = create_enrollment(client: client_unknown, project: project, entry_date: report_date)
      enrollment_nil = create_enrollment(client: client_nil, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_female, date: report_date)
      create_bed_night_service(enrollment: enrollment_male, date: report_date)
      create_bed_night_service(enrollment: enrollment_unknown, date: report_date)
      create_bed_night_service(enrollment: enrollment_nil, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    it 'counts clients by sex value' do
      expect(report.sex_count(0)).to eq(1) # Female
      expect(report.sex_count(1)).to eq(1) # Male
      expect(report.sex_count(8)).to eq(1) # Client doesn't know
      expect(report.sex_count(99)).to eq(1) # Data not collected (nil mapped to 99)
    end

    it 'returns 0 for sex values with no clients' do
      expect(report.sex_count(9)).to eq(0) # Client prefers not to answer
    end
  end

  describe '#sex_percentage' do
    let!(:client_female) { create_client_with_warehouse_link }
    let!(:client_male) { create_client_with_warehouse_link }

    before do
      client_female.warehouse_client_source.destination.update(Sex: 0)
      client_male.warehouse_client_source.destination.update(Sex: 1)

      enrollment_female = create_enrollment(client: client_female, project: project, entry_date: report_date)
      enrollment_male = create_enrollment(client: client_male, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_female, date: report_date)
      create_bed_night_service(enrollment: enrollment_male, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    it 'calculates percentage correctly' do
      # With 2 total clients, 1 female = 50%
      expect(report.sex_percentage(0)).to eq(50.0)
      expect(report.sex_percentage(1)).to eq(50.0)
    end

    it 'returns 0 for sex values with no clients' do
      expect(report.sex_percentage(8)).to eq(0)
    end
  end

  describe '#client_sexes_and_ages' do
    let!(:client_female) { create_client_with_warehouse_link(dob: report_date - 34.years) }
    let!(:client_male) { create_client_with_warehouse_link(dob: report_date - 39.years) }
    let!(:client_nil) { create_client_with_warehouse_link(dob: report_date - 24.years) }

    before do
      client_female.warehouse_client_source.destination.update(Sex: 0, DOB: report_date - 34.years)
      client_male.warehouse_client_source.destination.update(Sex: 1, DOB: report_date - 39.years)
      client_nil.warehouse_client_source.destination.update(Sex: nil, DOB: report_date - 24.years)

      enrollment_female = create_enrollment(client: client_female, project: project, entry_date: report_date)
      enrollment_male = create_enrollment(client: client_male, project: project, entry_date: report_date)
      enrollment_nil = create_enrollment(client: client_nil, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_female, date: report_date)
      create_bed_night_service(enrollment: enrollment_male, date: report_date)
      create_bed_night_service(enrollment: enrollment_nil, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    it 'maps nil values to 99 (Data not collected)' do
      sexes_and_ages = report.client_sexes_and_ages
      destination_client_id = client_nil.warehouse_client_source.destination_id
      client_data = sexes_and_ages[:count][destination_client_id]

      expect(client_data[:sex]).to eq(99)
    end

    it 'preserves separate values for 8, 9, and 99' do
      client_8 = create_client_with_warehouse_link
      client_9 = create_client_with_warehouse_link
      client_99 = create_client_with_warehouse_link

      client_8.warehouse_client_source.destination.update(Sex: 8)
      client_9.warehouse_client_source.destination.update(Sex: 9)
      client_99.warehouse_client_source.destination.update(Sex: 99)

      enrollment_8 = create_enrollment(client: client_8, project: project, entry_date: report_date)
      enrollment_9 = create_enrollment(client: client_9, project: project, entry_date: report_date)
      enrollment_99 = create_enrollment(client: client_99, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_8, date: report_date)
      create_bed_night_service(enrollment: enrollment_9, date: report_date)
      create_bed_night_service(enrollment: enrollment_99, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear

      sexes_and_ages = report.client_sexes_and_ages

      expect(sexes_and_ages[:count][client_8.warehouse_client_source.destination_id][:sex]).to eq(8)
      expect(sexes_and_ages[:count][client_9.warehouse_client_source.destination_id][:sex]).to eq(9)
      expect(sexes_and_ages[:count][client_99.warehouse_client_source.destination_id][:sex]).to eq(99)
    end

    it 'includes age data for each client' do
      sexes_and_ages = report.client_sexes_and_ages
      destination_client_id = client_female.warehouse_client_source.destination_id
      client_data = sexes_and_ages[:count][destination_client_id]

      expect(client_data).to have_key(:sex)
      expect(client_data).to have_key(:age)
      expect(client_data[:sex]).to eq(0)
      expect(client_data[:age]).to be_a(Integer)
    end
  end

  describe '#client_ids_in_sex' do
    let!(:client_female) { create_client_with_warehouse_link }
    let!(:client_male) { create_client_with_warehouse_link }

    before do
      client_female.warehouse_client_source.destination.update(Sex: 0)
      client_male.warehouse_client_source.destination.update(Sex: 1)

      enrollment_female = create_enrollment(client: client_female, project: project, entry_date: report_date)
      enrollment_male = create_enrollment(client: client_male, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_female, date: report_date)
      create_bed_night_service(enrollment: enrollment_male, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    it 'returns client IDs for the specified sex' do
      female_ids = report.client_ids_in_sex(0)
      male_ids = report.client_ids_in_sex(1)

      destination_female_id = client_female.warehouse_client_source.destination_id
      destination_male_id = client_male.warehouse_client_source.destination_id

      expect(female_ids).to include(destination_female_id)
      expect(female_ids).not_to include(destination_male_id)

      expect(male_ids).to include(destination_male_id)
      expect(male_ids).not_to include(destination_female_id)
    end
  end

  describe '#sex_age_count' do
    # Use actual age categories from the report
    # Female child: age 14 falls in (11..14) category
    # Female adult: age 22 falls in (18..24) category
    # Male child: age 12 falls in (11..14) category
    let!(:client_female_young) { create_client_with_warehouse_link(dob: report_date - 14.years) }
    let!(:client_female_adult) { create_client_with_warehouse_link(dob: report_date - 22.years) }
    let!(:client_male_young) { create_client_with_warehouse_link(dob: report_date - 12.years) }

    before do
      client_female_young.warehouse_client_source.destination.update(Sex: 0, DOB: report_date - 14.years)
      client_female_adult.warehouse_client_source.destination.update(Sex: 0, DOB: report_date - 22.years)
      client_male_young.warehouse_client_source.destination.update(Sex: 1, DOB: report_date - 12.years)

      enrollment_female_young = create_enrollment(client: client_female_young, project: project, entry_date: report_date)
      enrollment_female_adult = create_enrollment(client: client_female_adult, project: project, entry_date: report_date)
      enrollment_male_young = create_enrollment(client: client_male_young, project: project, entry_date: report_date)

      create_bed_night_service(enrollment: enrollment_female_young, date: report_date)
      create_bed_night_service(enrollment: enrollment_female_adult, date: report_date)
      create_bed_night_service(enrollment: enrollment_male_young, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear
    end

    it 'counts clients by sex and age range using actual age categories' do
      age_categories = report.age_categories

      # Calculate ages at report_date
      female_young_age = GrdaWarehouse::Hud::Client.age(dob: client_female_young.warehouse_client_source.destination.DOB, date: report_date)
      female_adult_age = GrdaWarehouse::Hud::Client.age(dob: client_female_adult.warehouse_client_source.destination.DOB, date: report_date)
      male_young_age = GrdaWarehouse::Hud::Client.age(dob: client_male_young.warehouse_client_source.destination.DOB, date: report_date)

      # Find the age ranges for each client
      cfy_range = age_categories.keys.find { |range| range.is_a?(Range) && range.include?(female_young_age) }
      cfa_range = age_categories.keys.find { |range| range.is_a?(Range) && range.include?(female_adult_age) }
      cmy_range = age_categories.keys.find { |range| range.is_a?(Range) && range.include?(male_young_age) }

      # Test the ranges that should have clients
      expect(report.sex_age_count(sex: 0, age_range: cfy_range)).to eq(1)
      expect(report.sex_age_count(sex: 0, age_range: cfa_range)).to eq(1)
      expect(report.sex_age_count(sex: 1, age_range: cmy_range)).to eq(1)

      # Test all other ranges should have 0 clients
      (age_categories.keys - [cfy_range, cfa_range]).each do |range|
        next if range.is_a?(Array) # Skip [nil] category

        expect(report.sex_age_count(sex: 0, age_range: range)).to eq(0),
                                                                  "Expected 0 female clients in age range #{range}"
      end

      (age_categories.keys - [cmy_range]).each do |range|
        next if range.is_a?(Array) # Skip [nil] category

        expect(report.sex_age_count(sex: 1, age_range: range)).to eq(0),
                                                                  "Expected 0 male clients in age range #{range}"
      end
    end
  end

  # The Demographic Summary report uses the same sex calculations as the Core Demographics Report,
  # so we are just doing smoke tests here to ensure the sex sections are included in the report.
  # The tests above cover the core sex calculations functionality that is shared across these two reports.
  describe 'DemographicSummary integration' do
    let(:demographic_summary_report) { CoreDemographicsReport::DemographicSummary::Report.new(filter) }

    it 'includes sex sections in overall_section_types' do
      section_types = CoreDemographicsReport::DemographicSummary::Report.overall_section_types

      expect(section_types).to include('sexes')
      expect(section_types).to include('sex_ages')
    end

    it 'includes sex data in export' do
      # Create a minimal client to ensure export methods can be called
      client = create_client_with_warehouse_link
      client.warehouse_client_source.destination.update(Sex: 0)
      enrollment = create_enrollment(client: client, project: project, entry_date: report_date)
      create_bed_night_service(enrollment: enrollment, date: report_date)

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
      Rails.cache.clear

      # Verify sex_data_for_export can be called without errors
      rows = {}
      expect { demographic_summary_report.sex_data_for_export(rows) }.not_to raise_error
      expect(rows).to have_key('*Sex Breakdowns')
      expect(rows).to have_key('*Sex/Age Breakdowns')
    end
  end
end
