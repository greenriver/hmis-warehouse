###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::ReportComponents::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  let!(:ds) { create :grda_warehouse_data_source }
  let!(:c1) { create :hud_client, data_source: ds }
  let!(:o1) { create :hud_organization, data_source: ds }
  let!(:p1) { create :hud_project, data_source: ds, organization: o1 }
  let!(:e1) { create :hud_enrollment, data_source: ds, project: p1, client: c1, relationship_to_hoh: 1, household_id: '123' }
  let!(:coc1) { create :hud_project_coc, data_source: ds, project_id: p1.project_id, state: 'MA' }
  let(:a) { create :csg_engage_agency }
  let(:p) { create :csg_engage_program, agency: a }
  let!(:pm) { create :csg_engage_program_mapping, project: p1, program: p }

  describe 'structure tests' do
    it 'should have the right structure' do
      report = MaReports::CsgEngage::ReportComponents::Report.new(p)
      result = nil
      expect { result = report.serialize }.not_to raise_error

      expect(result).to include(
        'AgencyID' => a.csg_engage_agency_id,
        'Data Type' => 'Households',
        'Action' => 'Import',
        'Programs' => contain_exactly(
          include(
            'Program Name' => p.csg_engage_name,
            'Import Keyword' => p.csg_engage_import_keyword,
            'Households' => contain_exactly(
              include(
                'Household Identifier' => have_attributes(length: 20),
                'Household Members' => contain_exactly(
                  include(
                    'Household Member' => include(
                      'Head Of Household' => 'Y',
                      'Is in Household' => 'Y',
                    ),
                  ),
                ),
                'Address' => be_present,
                'CSBG Data' => include(
                  'Number in House' => '1',
                ),
              ),
            ),
          ),
        ),
      )
    end
  end

  describe 'field tests' do
    describe 'gender values' do
      [
        [{ Man: 1 }, 'M'],
        [{ Woman: 1 }, 'F'],
        [{ Transgender: 1, Woman: 1 }, 'O'],
        [{ NonBinary: 1, Man: 1 }, 'O'],
        [{ CulturallySpecific: 1 }, 'O'],
        [{ DifferentIdentity: 1 }, 'O'],
        [{ Questioning: 1 }, 'O'],
        [{ GenderNone: 1 }, 'U'],
        [{}, 'U'],
      ].each do |attrs, expected|
        it "should have the right value (#{expected}) for values: #{attrs}" do
          c1.update!(**HudUtility2024.gender_id_to_field_name.values.uniq.map { |v| [v, 0] }.to_h, **attrs)
          result = MaReports::CsgEngage::ReportComponents::Report.new(p).serialize
          expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Household Member', 'Gender')).to eq(expected)
        end
      end
    end

    describe 'race values' do
      [
        [{ AmIndAKNative: 1 }, 'A', 'B', 'R'],
        [{ Asian: 1 }, 'C', 'D', 'S'],
        [{ BlackAfAmerican: 1 }, 'E', 'F', 'T'],
        [{ NativeHIPacific: 1 }, 'G', 'H', 'U'],
        [{ White: 1 }, 'I', 'J', 'V'],
        # Multi-racial
        [{ White: 1, Asian: 1, AmIndAKNative: 1 }, 'K', 'L', 'Q'],
        # Non-CSG race, should come through as other
        [{ MidEastNAfrican: 1 }, 'M', 'N', 'X'],
        [{ RaceNone: 99 }, 'O', 'P', 'W'],
      ].each do |attrs, expected_no_latino, expected_yes_latino, expected_unknown_latino|
        [
          [0, expected_no_latino],
          [1, expected_yes_latino],
          [99, expected_unknown_latino],
        ].each do |latino_val, expected|
          it "should have the right value (#{expected}) for ethnicity #{latino_val} and race: #{attrs}" do
            c1.update!(**HudUtility2024.race_id_to_field_name.values.uniq.map { |v| [v, 0] }.to_h, **attrs, HispanicLatinaeo: latino_val)
            result = MaReports::CsgEngage::ReportComponents::Report.new(p).serialize
            expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Household Member', 'Race 1/Ethnicity 1')).to eq(expected)
          end
        end
      end
    end

    describe 'income values' do
      it 'should have the right values for income' do
        income_benefit = create(
          :hud_income_benefit,
          enrollment: e1,
          data_source: ds,
          IncomeFromAnySource: 1,
          TotalMonthlyIncome: 120,
          Earned: 1,
          EarnedAmount: 1,
          Unemployment: 1,
          UnemploymentAmount: 2,
          SSI: 1,
          SSIAmount: 3,
          SSDI: 1,
          SSDIAmount: 4,
          VADisabilityService: 1,
          VADisabilityServiceAmount: 5,
          VADisabilityNonService: 1,
          VADisabilityNonServiceAmount: 6,
          PrivateDisability: 1,
          PrivateDisabilityAmount: 7,
          WorkersComp: 1,
          WorkersCompAmount: 8,
          TANF: 1,
          TANFAmount: 9,
          GA: 1,
          GAAmount: 10,
          SocSecRetirement: 1,
          SocSecRetirementAmount: 11,
          Pension: 1,
          PensionAmount: 12,
          ChildSupport: 1,
          ChildSupportAmount: 13,
          Alimony: 1,
          AlimonyAmount: 14,
          OtherIncomeSource: 1,
          OtherIncomeAmount: 15,
          OtherIncomeSourceIdentify: 'Stuff',
          BenefitsFromAnySource: 1,
        )
        result = MaReports::CsgEngage::ReportComponents::Report.new(p).serialize

        expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Income')).to(
          include(
            *MaReports::CsgEngage::ReportComponents::HouseholdMember::INCOME_MAPPINGS.map do |_field, amount_field, attrs|
              include(
                'Amount' => (income_benefit.send(amount_field) * 12.0).round,
                'Description' => attrs[:description],
                'IncomeSource' => attrs[:income_source],
              )
            end,
          ),
        )
      end
    end

    describe 'service values' do
      it 'should have the right values for a present service' do
        create(
          :hud_service,
          enrollment: e1,
          data_source: ds,
          date_provided: Date.today - 1.day,
        )
        s2 = create(
          :hud_service,
          enrollment: e1,
          data_source: ds,
          date_provided: Date.today,
        )
        result = MaReports::CsgEngage::ReportComponents::Report.new(p).serialize
        expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Services')).to(
          # Should only contain the latest service
          contain_exactly(
            include(
              'Service' => include(
                'ServiceProvided' => 'Unknown Service Type',
                'ServiceDateTimeBegin' => s2.DateProvided.strftime('%m/%d/%Y'),
              ),
            ),
          ),
        )
      end

      it 'should have the right values for a member without any services' do
        create(
          :hud_exit,
          enrollment: e1,
          data_source: ds,
          exit_date: Date.today,
        )
        result = MaReports::CsgEngage::ReportComponents::Report.new(p).serialize
        expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Services')).to(
          contain_exactly(
            include(
              'Service' => include(
                'ServiceDateTimeBegin' => e1.EntryDate.strftime('%m/%d/%Y'),
                'ServiceDateTimeEnd' => e1.exit.ExitDate.strftime('%m/%d/%Y'),
                'ServiceProvided' => 'Project Enrollment',
              ),
            ),
          ),
        )
      end
    end
  end
end
