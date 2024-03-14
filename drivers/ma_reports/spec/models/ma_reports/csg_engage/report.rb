###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe MaReports::CsgEngage::Report, type: :model do
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

  describe 'structure tests' do
    it 'should have the right structure' do
      report = MaReports::CsgEngage::Report.new(GrdaWarehouse::Hud::Project.where(id: p1.id), agency_id: 999)
      result = nil
      expect { result = report.serialize }.not_to raise_error

      expect(result).to include(
        'AgencyID' => 999,
        'Data Type' => 'Households',
        'Action' => 'Import',
        'Programs' => contain_exactly(
          include(
            'Program Name' => p1.project_name,
            'Import Keyword' => p1.project_id,
            'Households' => contain_exactly(
              include(
                'Household Identifier' => e1.household_id,
                'Household Members' => contain_exactly(
                  include(
                    'Household Member Identifier' => c1.personal_id,
                    'Household Member' => include(
                      'Head Of Household' => 'Y',
                      'Is in Household' => 'Y',
                    ),
                  ),
                ),
                'Address' => be_present,
                'CSBG Data' => include(
                  'Number in House' => 1,
                ),
                'Other Address' => be_empty,
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
          result = MaReports::CsgEngage::Report.new(GrdaWarehouse::Hud::Project.where(id: p1.id)).serialize
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
            result = MaReports::CsgEngage::Report.new(GrdaWarehouse::Hud::Project.where(id: p1.id)).serialize
            expect(result.dig('Programs', 0, 'Households', 0, 'Household Members', 0, 'Household Member', 'Race 1/Ethnicity 1')).to eq(expected)
          end
        end
      end
    end
  end
end
