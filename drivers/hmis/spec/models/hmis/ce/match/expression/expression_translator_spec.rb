###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::ExpressionTranslator do
  let!(:custom_assessment_form) do
    create(
      :hmis_form_definition,
      identifier: 'score_assessment',
      title: 'Score Assessment',
      role: :CUSTOM_ASSESSMENT,
      status: :published,
    )
  end
  let!(:score_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'score',
      label: 'Score',
      field_type: :integer,
      form_definition: custom_assessment_form,
      data_source: custom_assessment_form.data_source,
    )
  end
  let!(:preferred_bedroom_size_cded) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'housing_needs_preferred_bedroom_size',
      label: 'Preferred Bedroom Size',
      field_type: :string,
      repeats: true,
      form_definition: custom_assessment_form,
      data_source: custom_assessment_form.data_source,
    )
  end

  describe '.to_structured' do
    it 'returns nil for blank expression' do
      expect(described_class.to_structured(nil)).to be_nil
      expect(described_class.to_structured('   ')).to be_nil
    end

    it 'returns nil for parse errors' do
      expect(described_class.to_structured('this is not an expression')).to be_nil
    end

    it 'parses a single comparison as implicit AND' do
      structured = described_class.to_structured('current_age >= 18')
      expect(structured.operator).to eq(:AND)
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to eq(
        Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'current_age', comparator: :GTE, value: 18, field_source: :CLIENT, form_definition_identifier: nil),
      )
    end

    it 'parses flat AND' do
      expr = 'current_age >= 18 AND veteran_status = 1 AND days_since_last_exit = 10'
      structured = described_class.to_structured(expr)
      expect(structured.operator).to eq(:AND)
      expect(structured.clauses.map(&:comparator)).to eq([:GTE, :EQ, :EQ])
      expect(structured.clauses.map(&:field)).to eq(['current_age', 'veteran_status', 'days_since_last_exit'])
    end

    it 'parses flat OR' do
      expr = 'current_age = 1 OR veteran_status = 2 OR days_since_last_exit = 3'
      structured = described_class.to_structured(expr)
      expect(structured.operator).to eq(:OR)
      expect(structured.clauses.size).to eq(3)
    end

    it 'parses INCLUDES with backtick field identifier' do
      expr = 'INCLUDES(`cde.custom_assessment.housing_needs_preferred_bedroom_size`, "1 Bed")'
      structured = described_class.to_structured(expr)
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(
        field: 'cde.custom_assessment.housing_needs_preferred_bedroom_size',
        comparator: :INCLUDES,
        value: '1 Bed',
      )
    end

    it 'parses EXCLUDES' do
      structured = described_class.to_structured('EXCLUDES(open_referral_project_types, 1)')
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(field: 'open_referral_project_types', comparator: :EXCLUDES, value: Types::HmisSchema::Enums::ProjectType.key_for(1))
    end

    it 'parses EQ with NULL RHS' do
      structured = described_class.to_structured('current_age = NULL')
      expect(structured.clauses.size).to eq(1)
      expect(structured.clauses.first).to have_attributes(field: 'current_age', comparator: :EQ, value: nil)
    end

    it 'coerces enum-backed Dentaku literals to frontend enum keys' do
      structured = described_class.to_structured('veteran_status = 1')

      expect(structured.clauses.first).to have_attributes(field: 'veteran_status', comparator: :EQ, value: 'YES')
    end

    it 'recovers CDED pick list metadata from the CDED form context' do
      data_source = create(:hmis_data_source)
      form_definition = create(
        :hmis_form_definition,
        identifier: 'ce_picklist_assessment',
        role: :CUSTOM_ASSESSMENT,
        status: :published,
        data_source: data_source,
        definition: {
          'item' => [
            {
              'type' => 'CHOICE',
              'link_id' => 'ce_veteran_status',
              'text' => 'CE Veteran Status',
              'pick_list_reference' => 'NoYesReasonsForMissingData',
              'mapping' => { 'custom_field_key' => 'ce_veteran_status' },
            },
          ],
        },
      )
      create(
        :hmis_custom_data_element_definition,
        owner_type: 'Hmis::Hud::CustomAssessment',
        key: 'ce_veteran_status',
        label: 'CE Veteran Status',
        field_type: :integer,
        form_definition: form_definition,
        data_source: data_source,
      )

      structured = described_class.to_structured('`cde.custom_assessment.ce_veteran_status` = 1')

      expect(structured.clauses.first).to have_attributes(
        field: 'cde.custom_assessment.ce_veteran_status',
        comparator: :EQ,
        value: 'YES',
        field_source: :CUSTOM_DATA_ELEMENT,
        form_definition_identifier: form_definition.identifier,
      )
    end

    it 'returns nil for unknown fields' do
      expect(described_class.to_structured('unknown_field = 1')).to be_nil
    end

    it 'leaves unrecognized enum-backed Dentaku literals unchanged' do
      structured = described_class.to_structured('veteran_status = 12345')

      expect(structured.clauses.first).to have_attributes(field: 'veteran_status', comparator: :EQ, value: 12_345)
    end

    it 'returns nil for INCLUDES with arguments in wrong order' do
      expect(described_class.to_structured('INCLUDES("1 Bed", open_referral_project_types)')).to be_nil
    end

    it 'returns nil when AND and OR are mixed at the same level' do
      expect(described_class.to_structured('current_age = 1 OR veteran_status = 2 AND days_since_last_exit = 3')).to be_nil
    end

    it 'returns nil for nested boolean under a flat combinator' do
      expect(described_class.to_structured('current_age = 1 OR (veteran_status = 2 AND days_since_last_exit = 3)')).to be_nil
    end

    it 'returns nil for disallowed functions' do
      expect(described_class.to_structured('PROJECT_TYPE(x) = "ES"')).to be_nil
    end

    it 'returns nil when comparing two identifiers' do
      expect(described_class.to_structured('current_age = veteran_status')).to be_nil
    end

    it 'returns nil for arithmetic' do
      expect(described_class.to_structured('current_age + 1 = 2')).to be_nil
    end
  end

  describe 'round-trip' do
    it 'preserves structured form for AND expressions' do
      original = 'current_age >= 18 AND veteran_status = 1'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for OR expressions' do
      original = 'current_age = 1 OR veteran_status = 2'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for INCLUDES in an AND chain' do
      original = 'INCLUDES(open_referral_project_types, 1) AND current_age = 1'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form for EXCLUDES in an OR chain' do
      original = 'EXCLUDES(open_referral_project_types, 2) OR current_age = NULL'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end

    it 'preserves structured form when clause value is NULL' do
      original = 'current_age = NULL'
      structured = described_class.to_structured(original)
      round = described_class.to_structured(described_class.from_structured(structured))
      expect(round).to eq(structured)
    end
  end

  describe '.from_structured' do
    it 'coerces enum-backed UI values before serializing Dentaku expressions' do
      structured = Hmis::Ce::Match::Expression::StructuredExpression.new(
        operator: :AND,
        clauses: [
          Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'veteran_status', comparator: :EQ, value: 'YES', field_source: nil, form_definition_identifier: nil),
        ],
      )

      expect(described_class.from_structured(structured)).to eq('veteran_status = 1')
    end

    it 'coerces enum-backed UI values generically using the field pick list reference' do
      emergency_shelter_key = Types::HmisSchema::Enums::ProjectType.key_for(1)
      structured = Hmis::Ce::Match::Expression::StructuredExpression.new(
        operator: :AND,
        clauses: [
          Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'open_referral_project_types', comparator: :INCLUDES, value: emergency_shelter_key, field_source: nil, form_definition_identifier: nil),
        ],
      )

      expect(described_class.from_structured(structured)).to eq('INCLUDES(open_referral_project_types, 1)')
    end

    it 'leaves unknown fields and unrecognized enum keys unchanged' do
      structured = Hmis::Ce::Match::Expression::StructuredExpression.new(
        operator: :AND,
        clauses: [
          Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'unknown_field', comparator: :EQ, value: 'YES', field_source: nil, form_definition_identifier: nil),
          Hmis::Ce::Match::Expression::StructuredExpression::Clause.new(field: 'veteran_status', comparator: :EQ, value: 'NOT_A_REAL_KEY', field_source: nil, form_definition_identifier: nil),
        ],
      )

      expect(described_class.from_structured(structured)).to eq("unknown_field = 'YES' AND veteran_status = 'NOT_A_REAL_KEY'")
    end
  end
end
