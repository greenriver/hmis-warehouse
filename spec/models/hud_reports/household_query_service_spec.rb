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

  describe 'semantic scope extensions (Dynamic Filters)' do
    let(:apr_table) { HudApr::Fy2020::AprClient.arel_table }
    let(:apr_service) { described_class.new(report, apr_table) }
    # In reports, we often extend a UniverseMember relation that has joined the universe model
    let(:base_relation) { HudReports::UniverseMember.all }
    let(:extended_scope) { apr_service.with_household_context(base_relation) }

    it 'correctly resolves columns from the universe table rather than the base relation table' do
      # strict_leavers uses 'last_date_in_program', which exists on AprClient but NOT UniverseMember
      sql = extended_scope.strict_leavers(Date.current).to_sql

      # It should use "hud_report_apr_clients" (from apr_table) not "hud_report_universe_members"
      expect(sql).to include('"hud_report_apr_clients"."last_date_in_program"')
      expect(sql).not_to include('"hud_report_universe_members"."last_date_in_program"')
    end

    it 'chains multiple scopes using the correct tables' do
      sql = extended_scope.heads_of_household.without_children.to_sql

      expect(sql).to match(/"hh_ctx"\."is_hoh" = (true|TRUE)/)
      expect(sql).to include('"hh_ctx"."household_type" = \'adults_only\'')
    end

    it 'correctly handles age-based scopes' do
      sql = extended_scope.adults_or_hohs.to_sql

      # Should use hh_ctx for age and is_hoh
      expect(sql).to include('"hh_ctx"."age" >= 18')
      expect(sql).to match(/"hh_ctx"\."is_hoh" = (true|TRUE)/)
    end
  end
end
