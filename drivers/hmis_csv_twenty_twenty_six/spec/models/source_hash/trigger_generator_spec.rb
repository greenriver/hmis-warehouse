###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::SourceHash::TriggerGenerator do
  subject(:generator) { described_class }

  describe '.column_expression' do
    it 'renders text columns as-is, NULL-coalesced' do
      expect(generator.column_expression('FirstName', :string)).
        to eq(%q{COALESCE(NEW."FirstName", E'\x1f')})
    end

    it 'casts integer columns to text' do
      expect(generator.column_expression('DisabilityType', :integer)).
        to eq(%q{COALESCE(NEW."DisabilityType"::text, E'\x1f')})
    end

    it 'renders dates with a GUC-independent mask' do
      expect(generator.column_expression('InformationDate', :date)).
        to eq(%q{COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f')})
    end

    it 'renders timestamps with microsecond precision' do
      expect(generator.column_expression('DateCreated', :datetime)).
        to eq(%q{COALESCE(to_char(NEW."DateCreated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f')})
    end
  end

  describe 'canonical column set' do
    it 'excludes ExportID but keeps it driven by hmis_structure order' do
      klass = HmisCsvTwentyTwentySix::Importer::Disability
      columns = generator.hash_columns(klass).map(&:first)
      expect(columns).not_to include('ExportID')
      expected = klass.hmis_structure(version: '2026').keys.map(&:to_s) - ['ExportID']
      expect(columns).to eq(expected)
    end

    it 'watches exactly the hashed columns on UPDATE' do
      klass = HmisCsvTwentyTwentySix::Importer::Disability
      expect(generator.update_of_columns(klass)).to eq(generator.hash_columns(klass).map(&:first))
    end
  end
end
