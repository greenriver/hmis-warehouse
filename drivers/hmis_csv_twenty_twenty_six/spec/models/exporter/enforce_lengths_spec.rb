###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::ExportConcern do
  let(:test_class) do
    Class.new do
      include HmisCsvTwentyTwentySix::Exporter::ExportConcern

      def initialize(options)
        @options = options
      end

      def length_limited_columns
        {
          ShortField: { limit: 10 },
          LongField: { limit: 250 },
        }
      end
    end
  end

  let(:options) { { export: double('export') } }
  let(:instance) { test_class.new(options) }

  describe '#enforce_lengths' do
    it 'truncates fields that exceed their limit' do
      row = { ShortField: 'A' * 15, LongField: 'B' * 300 }

      result = instance.enforce_lengths(row)

      expect(result[:ShortField].length).to eq 10
      expect(result[:LongField].length).to eq 250
    end

    it 'does not modify fields within their limit' do
      row = { ShortField: 'Hello', LongField: 'B' * 250 }

      result = instance.enforce_lengths(row)

      expect(result[:ShortField]).to eq 'Hello'
      expect(result[:LongField].length).to eq 250
    end

    it 'replaces newlines with spaces before truncating' do
      row = { ShortField: "Hello\nWorld" }

      result = instance.enforce_lengths(row)

      expect(result[:ShortField]).to eq 'Hello Worl'
    end

    it 'does not truncate non-string fields' do
      row = { ShortField: 12_345_678_901 }

      result = instance.enforce_lengths(row)

      expect(result[:ShortField]).to eq 12_345_678_901
    end

    it 'skips blank fields' do
      row = { ShortField: nil, LongField: '' }

      result = instance.enforce_lengths(row)

      expect(result[:ShortField]).to be_nil
      expect(result[:LongField]).to eq ''
    end

    context 'with non-breaking spaces ( )' do
      let(:nbsp) { "\u00A0" }

      it 'preserves non-breaking spaces in fields within the limit' do
        value = "Hello#{nbsp}World"
        row = { ShortField: value }

        result = instance.enforce_lengths(row)

        expect(result[:ShortField]).to eq "Hello#{nbsp}Worl"
        expect(result[:ShortField]).to include(nbsp)
      end

      it 'counts non-breaking spaces as one character when truncating' do
        # 11 chars with NBSP at position 5 — should truncate to 10, keeping the NBSP
        value = "Hell#{nbsp}World!!"
        row = { ShortField: value }

        result = instance.enforce_lengths(row)

        expect(result[:ShortField].length).to eq 10
        expect(result[:ShortField]).to include(nbsp)
      end

      it 'truncates correctly when non-breaking spaces push a field over the limit' do
        # 250 ASCII chars + 1 NBSP = 251 chars, must truncate to 250
        value = ('A' * 250) + nbsp
        row = { LongField: value }

        result = instance.enforce_lengths(row)

        expect(result[:LongField].length).to eq 250
      end
    end
  end
end
