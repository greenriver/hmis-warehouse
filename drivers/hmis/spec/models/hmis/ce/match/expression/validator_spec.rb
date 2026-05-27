# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::Validator do
  let!(:hmis_data_source) { create(:hmis_data_source) }

  describe 'valid expressions' do
    it 'returns no errors for a supported client field expression' do
      expect(described_class.call('current_age >= 18').errors).to be_empty
    end

    it 'returns no errors for CE custom functions' do
      expect(described_class.call('INCLUDES(open_enrollment_project_types, 1)').errors).to be_empty
      expect(described_class.call('EXCLUDES(open_enrollment_project_types, 1)').errors).to be_empty
      expect(described_class.call('PROJECT_TYPE("ES") = "ES"').errors).to be_empty
    end

    it 'returns no errors for Dentaku built-in functions' do
      expect(described_class.call('MAX(current_age, 18) > 10').errors).to be_empty
      expect(described_class.call('IF(current_age >= 18, 1, 0) = 1').errors).to be_empty
    end

    context 'with a known CDE field' do
      let!(:form_definition) { create(:hmis_form_definition, identifier: 'test_form', data_source: hmis_data_source) }
      let!(:cded) do
        create(
          :hmis_custom_data_element_definition,
          owner_type: 'Hmis::Hud::CustomAssessment',
          key: 'language_preference',
          field_type: 'string',
          form_definition_identifier: 'test_form',
          data_source: hmis_data_source,
        )
      end

      it 'returns no errors' do
        expression = '`cde.custom_assessment.language_preference` = "English"'
        expect(described_class.call(expression).errors).to be_empty
      end
    end
  end

  describe 'blank expression' do
    it 'returns a required error' do
      errors = described_class.call('').errors

      expect(errors.map(&:type)).to eq([:required])
      expect(errors.first.attribute).to eq(:expression)
    end
  end

  describe 'parse errors' do
    it 'returns an invalid error with the parser message' do
      errors = described_class.call('this is not an expression').errors

      expect(errors).not_to be_empty
      expect(errors.first).to have_attributes(attribute: :expression, type: :invalid)
      expect(errors.first.message).to include('Invalid statement')
    end

    it 'returns an invalid error for an undefined function' do
      errors = described_class.call('NOT_A_REAL_FUNCTION(current_age)').errors

      expect(errors.first.message).to include('Undefined function')
    end
  end

  describe 'unknown client field' do
    it 'returns an invalid error' do
      errors = described_class.call('not_a_real_field = 1').errors

      expect(errors.first.message).to include('Field "not_a_real_field" is not supported')
    end

    it 'returns an invalid error when the unknown field is inside an allowlisted function' do
      errors = described_class.call('INCLUDES(not_a_real_field, 1)').errors

      expect(errors.first.message).to include('Field "not_a_real_field" is not supported')
    end
  end

  describe 'unknown CDE field' do
    it 'returns an invalid error' do
      errors = described_class.call('`cde.custom_assessment.nonexistent_field` = 1').errors

      expect(errors.first.message).to include('Unknown CDE')
    end
  end
end
