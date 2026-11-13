###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportGenerators::SystemPerformance::Fy2019::Base, type: :model do
  let(:generator) { described_class.new({}) }
  let(:scope) { GrdaWarehouse::ServiceHistoryEnrollment.all }

  describe '#sub_population_scope' do
    it 'raises for an unregistered sub-population' do
      expect { generator.sub_population_scope(scope, 'entry') }.to raise_error(ArgumentError)
    end

    it 'serves a legacy key from its mapped scope' do
      expect(generator.sub_population_scope(scope, 'youth').to_sql).to eq(scope.unaccompanied_youth.to_sql)
    end

    it 'dispatches a registered sub-population' do
      expect(generator.sub_population_scope(scope, 'veterans').to_sql).to eq(scope.veterans.to_sql)
    end
  end
end
