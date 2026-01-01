# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::HouseholdQueryService, type: :model do
  let(:report) { create(:hud_reports_report_instance) }
  let(:table) { GrdaWarehouse::ServiceHistoryEnrollment.arel_table }
  let(:service) { described_class.new(report, table) }

  describe '#with_household_context' do
    it 'uses a LEFT OUTER JOIN' do
      scope = service.with_household_context(GrdaWarehouse::ServiceHistoryEnrollment.all)
      expect(scope.to_sql).to include('LEFT OUTER JOIN "hud_report_household_contexts" "hh_ctx"')
    end

    it 'filters by report_instance_id' do
      scope = service.with_household_context(GrdaWarehouse::ServiceHistoryEnrollment.all)
      expect(scope.to_sql).to include("\"hh_ctx\".\"report_instance_id\" = #{report.id}")
    end

    it 'includes records even when no context exists (due to LEFT JOIN)' do
      # Create an enrollment but NO context
      enrollment = create(:she_entry, data_source_id: 1)

      scope = service.with_household_context(GrdaWarehouse::ServiceHistoryEnrollment.where(id: enrollment.id))
      expect(scope).to include(enrollment)
    end
  end

  describe '#sub_populations' do
    it 'defines correct sub-population clauses using the context table' do
      expect(service.sub_populations['Without Children'].to_sql).to include('"hh_ctx"."household_type" = \'adults_only\'')
      expect(service.sub_populations['With Children and Adults'].to_sql).to include('"hh_ctx"."household_type" = \'adults_and_children\'')
      expect(service.sub_populations['Chronically Homeless'].to_sql).to match(/"hh_ctx"\."inherited_chronic_status" = (true|TRUE)/)
    end
  end
end
