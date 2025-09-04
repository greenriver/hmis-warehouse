# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Importers::HousingAssessmentImporter do
  describe '#complete_assessment' do
    # Minimal fake CDED + CDE collection to capture writes without hitting DB
    class FakeCded
      attr_reader :key, :field_type
      def initialize(key:, field_type: 'string')
        @key = key
        @field_type = field_type
      end
    end

    class FakeCde
      attr_reader :definition, :values
      def initialize(definition:)
        @definition = definition
        @values = {}
      end

      def []=(name, value)
        @values[name] = value
      end

      def save!
        true
      end
    end

    class FakeCdeCollection
      attr_reader :built
      def initialize
        @built = []
      end

      def build(data_element_definition:, user:, data_source_id:)
        cde = FakeCde.new(definition: data_element_definition)
        @built << cde
        cde
      end
    end

    let(:importer) { described_class.new }
    let(:assessment) { OpenStruct.new(data_source_id: 1, custom_data_elements: FakeCdeCollection.new) }

    # Return a CDED for any key to prevent KeyError from fetch
    let(:cded_fetcher) do
      Class.new do
        def fetch(key)
          # Use string type for simplicity; importer sets value_<field_type>
          FakeCded.new(key: key, field_type: 'string')
        end
      end.new
    end

    before do
      allow(importer).to receive(:cded_lookup).and_return(cded_fetcher)
      allow(importer).to receive(:system_hud_user).and_return(OpenStruct.new(user_id: 123))
    end

    def cde_value_for(collection, cded_key)
      recs = collection.built.select { |cde| cde.definition.key == cded_key }
      expect(recs).to be_present, "Expected CDE for #{cded_key} to be created"
      values = recs.map { |rec| rec.values['value_string'] }
      values.length == 1 ? values.first : values
    end

    it 'maps CSV values and derived fields into assessment CDEs' do
      header = described_class::COLUMN_NAMES
      row = [
        '12345',               # client_id
        '1980-01-01',          # client_dob
        'FIRST',               # client_first_name
        'LAST',                # client_last_name
        '12345',               # client_mci_id
        '2023-10-01 10:00:00', # date_created
        '2023-10-02 12:30:00', # date_updated
        '2023-10-02',          # assessment_date
        'No',                  # chronically_homeless
        8,                     # aha_score
        4,                     # alt_aha_score
        'Yes',                 # anyone_in_household_service_in_military
        'No',                  # anyone_in_household_megans_law
        'Yes',                 # anyone_in_household_disability
        'No',                  # anyone_in_household_hiv_aids
        'Yes',                 # anyone_in_household_mental_health
        'No',                  # anyone_in_household_substance_use
        'Yes',                 # anyone_in_household_needs_wheelchair_accessible_unit
        'No',                  # anyone_in_household_pregnant
        15.0,                  # income_percentage_ami
        73.0,                  # income_percentage_fpl
        'SRO|0|1',             # referred_bedroom_sizes
        'Households without Children', # household_composition
        'No',                  # tay
        1,                     # household_size
        1,                     # dob_data_quality
        '111111111',           # ssn
        1,                     # ssn_data_quality
        '1~White',             # race_common_desc
        '2~Not Hispanic/Latinx', # ethnic_common_desc
        '2~Female', # gender_common_desc
        'Yes', # vetern_flag
      ]

      attrs = header.zip(row).to_h.symbolize_keys
      waitlist = described_class::Waitlist.new(attrs, row_number: 2)

      # Exercise mapping
      importer.send(:complete_assessment, waitlist, assessment)

      cdes = assessment.custom_data_elements

      # Household composition translated
      expect(cde_value_for(cdes, 'housing_needs_household_composition')).to eq('Individual')
      # Bedroom sizes normalized (0 -> SRO, 1 -> 1 Bed)
      expect(cde_value_for(cdes, 'housing_needs_preferred_bedroom_size')).to match_array(['SRO', '1 Bed'])

      # Pair fields set for household and aggregate
      expect(cde_value_for(cdes, 'housing_needs_military_service')).to eq('Yes')
      expect(cde_value_for(cdes, 'housing_needs_military_service_individual')).to eq('Yes')
      expect(cde_value_for(cdes, 'housing_needs_living_with_disability')).to eq('Yes')
      expect(cde_value_for(cdes, 'housing_needs_living_with_disability_individual')).to eq('Yes')

      # Additional fields wired
      expect(cde_value_for(cdes, 'housing_needs_number_of_household_members')).to eq(1)
      expect(cde_value_for(cdes, 'housing_needs_eligible_for_projects_serving_gender')).to eq('Only Those Identifying as Female')
      expect(cde_value_for(cdes, 'housing_needs_any_household_income')).to eq('Yes')

      # AHA score mapped
      expect(cde_value_for(cdes, 'housing_needs_aha_score')).to eq(8)

      # Alt-AHA score mapped
      expect(cde_value_for(cdes, 'housing_needs_alternative_assessment_score')).to eq(4)

      # Percentages carried through
      expect(cde_value_for(cdes, 'housing_needs_ami')).to eq(15.0)
      expect(cde_value_for(cdes, 'housing_needs_fpl')).to eq(73.0)

      # TAY flag
      expect(cde_value_for(cdes, 'housing_needs_transition_aged_youth')).to eq('No')

      # Chronically homeless value
      expect(cde_value_for(cdes, 'housing_needs_chronically_homeless')).to eq('No')

      # Other paired individual + aggregate fields
      expect(cde_value_for(cdes, 'housing_needs_megans_law')).to eq('No')
      expect(cde_value_for(cdes, 'housing_needs_megans_law_individual')).to eq('No')

      expect(cde_value_for(cdes, 'housing_needs_living_with_hiv_aids')).to eq('No')
      expect(cde_value_for(cdes, 'housing_needs_living_with_hiv_aids_individual')).to eq('No')

      expect(cde_value_for(cdes, 'housing_needs_mental_health_diagnosis')).to eq('Yes')
      expect(cde_value_for(cdes, 'housing_needs_mental_health_diagnosis_individual')).to eq('Yes')

      expect(cde_value_for(cdes, 'housing_needs_substance_use_disorder')).to eq('No')
      expect(cde_value_for(cdes, 'housing_needs_substance_use_disorder_individual')).to eq('No')

      expect(cde_value_for(cdes, 'housing_needs_wheelchair_accessible_unit')).to eq('Yes')
      expect(cde_value_for(cdes, 'housing_needs_wheelchair_accessible_unit_individual')).to eq('Yes')

      expect(cde_value_for(cdes, 'housing_needs_currently_pregnant')).to eq('No')
      expect(cde_value_for(cdes, 'housing_needs_currently_pregnant_individual')).to eq('No')

      # Monthly income estimation fitted to both AMI and FPL integer % rounding
      # size=1; AMI=15%, FPL=73% → intersection midpoint ≈ 951.92
      expect(cde_value_for(cdes, 'housing_needs_monthly_household_income')).to eq(951.92)
    end

    it 'parses dates correctly for waitlist accessors' do
      attrs = {
        client_id: '99999', client_dob: '1970-12-31', client_first_name: 'A', client_last_name: 'B', client_mci_id: 'X',
        date_created: '2024-01-01 09:30:00', date_updated: '2024-01-02 10:00:00', assessment_date: '2024-01-02',
        chronically_homeless: 'No', aha_score: 1, alt_aha_score: nil,
        anyone_in_household_service_in_military: 'No', anyone_in_household_megans_law: 'No', anyone_in_household_disability: 'No',
        anyone_in_household_hiv_aids: 'No', anyone_in_household_mental_health: 'No', anyone_in_household_substance_use: 'No',
        anyone_in_household_needs_wheelchair_accessible_unit: 'No', anyone_in_household_pregnant: 'No',
        income_percentage_ami: 50.0, income_percentage_fpl: 50.0,
        referred_bedroom_sizes: '2|SRO', household_composition: 'Households with Children', tay: 'No',
        household_size: 3, dob_data_quality: 1, ssn: '000000000', ssn_data_quality: 1,
        race_common_desc: '1~White', ethnic_common_desc: '1~Hispanic/Latinx', gender_common_desc: '1~Male', vetern_flag: 'No'
      }
      waitlist = described_class::Waitlist.new(attrs, row_number: 3)

      expect(waitlist.assessment_date).to be_a(Date)
      expect(waitlist.date_created).to be_a(DateTime)
      expect(waitlist.client_dob).to be_a(Date)
      expect(waitlist.household_type).to eq('Household with minors')
      expect(waitlist.referred_bedroom_sizes).to match_array(['2 Bed', 'SRO'])
    end
  end
end
