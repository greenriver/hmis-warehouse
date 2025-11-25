###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::ExportConcern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include HmisCsvTwentyTwentySix::Exporter::ExportConcern

      def initialize(options)
        @options = options
      end
    end
  end

  let(:options) { { export: double('export') } }
  let(:instance) { test_class.new(options) }

  describe '#sanitize_string_fields' do
    it 'removes forbidden characters from string fields' do
      row = {
        Field1: 'Text with <brackets>',
        Field2: 'Text with [square] brackets',
        Field3: 'Text with {curly} braces',
        Field4: 'Text with all < > [ ] { }',
        Field5: 'Normal text',
        Field6: '  Normal text  ',
      }

      result = instance.sanitize_string_fields(row)

      expect(result[:Field1]).to eq 'Text with brackets'
      expect(result[:Field2]).to eq 'Text with square brackets'
      expect(result[:Field3]).to eq 'Text with curly braces'
      expect(result[:Field4]).to eq 'Text with all'
      expect(result[:Field5]).to eq 'Normal text'
      expect(result[:Field6]).to eq 'Normal text'
    end

    it 'does not modify non-string fields' do
      row = {
        StringField: 'Text <with> brackets',
        IntegerField: 123,
        DateField: Date.today,
        NilField: nil,
        BooleanField: true,
      }

      result = instance.sanitize_string_fields(row)

      expect(result[:StringField]).to eq 'Text with brackets'
      expect(result[:IntegerField]).to eq 123
      expect(result[:DateField]).to eq Date.today
      expect(result[:NilField]).to be_nil
      expect(result[:BooleanField]).to eq true
    end

    it 'handles empty strings' do
      row = {
        EmptyField: '',
        BlankField: '   ',
      }

      result = instance.sanitize_string_fields(row)

      expect(result[:EmptyField]).to eq ''
      expect(result[:BlankField]).to eq ''
    end

    it 'handles strings with only forbidden characters' do
      row = {
        OnlyForbidden: '<>[]{}',
      }

      result = instance.sanitize_string_fields(row)

      expect(result[:OnlyForbidden]).to eq ''
    end

    it 'preserves other special characters' do
      row = {
        SpecialChars: 'Text with !@#$%^&*()_+-=,./?;:\'"',
      }

      result = instance.sanitize_string_fields(row)

      expect(result[:SpecialChars]).to eq 'Text with !@#$%^&*()_+-=,./?;:\'"'
    end

    it 'handles hash with indifferent access' do
      row = ActiveSupport::HashWithIndifferentAccess.new(
        'Field1' => 'Text <with> brackets',
        'Field2' => 'Normal text',
      )

      result = instance.sanitize_string_fields(row)

      expect(result['Field1']).to eq 'Text with brackets'
      expect(result['Field2']).to eq 'Normal text'
    end

    it 'returns the same row object' do
      row = { Field1: 'Text <with> brackets' }

      result = instance.sanitize_string_fields(row)

      expect(result).to be(row)
    end
  end
end
