###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'cohort:add_matched_tab', type: :task do
  let(:task_name) { 'cohort:add_matched_tab' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'cohort:add_matched_tab' }
  end

  before do
    Rake::Task[task_name].reenable
  end

  let!(:cohort) { create(:cohort) }

  def create_default_tabs_for(cohort)
    GrdaWarehouse::CohortTab.default_rules.each do |rule|
      cohort.cohort_tabs.create!(**rule)
    end
  end

  context 'with a cohort that has default tabs' do
    before do
      create_default_tabs_for(cohort)
      Rake::Task[task_name].invoke(cohort.id)
    end

    it 'generates correct SQL for the Matched tab' do
      matched_tab = cohort.cohort_tabs.find_by(name: 'Matched')
      sql = GrdaWarehouse::CohortTab.new.rule_query(nil, matched_tab.rules).to_sql
      expect(sql).to eq(
        '(("cohort_clients"."destination" IS NULL OR "cohort_clients"."destination" = \'\') OR "cohort_clients"."housed_date" IS NULL) AND ("cohort_clients"."ineligible" IS NULL OR "cohort_clients"."ineligible" = FALSE) AND "cohort_clients"."active" = TRUE AND "cohort_clients"."user_boolean_1" = TRUE AND "cohort_clients"."user_string_1" IS NOT NULL AND "cohort_clients"."user_string_1" != \'\'',
      )
    end

    it 'generates correct SQL for the updated Active Clients tab' do
      active_tab = cohort.cohort_tabs.find_by(name: 'Active Clients')
      sql = GrdaWarehouse::CohortTab.new.rule_query(nil, active_tab.rules).to_sql
      expect(sql).to eq(
        '(("cohort_clients"."destination" IS NULL OR "cohort_clients"."destination" = \'\') OR "cohort_clients"."housed_date" IS NULL) AND ("cohort_clients"."ineligible" IS NULL OR "cohort_clients"."ineligible" = FALSE) AND "cohort_clients"."active" = TRUE AND NOT (COALESCE(("cohort_clients"."user_boolean_1" = TRUE AND "cohort_clients"."user_string_1" IS NOT NULL AND "cohort_clients"."user_string_1" != \'\'), FALSE))',
      )
    end

    it 'places Matched tab between Active Clients and Housed' do
      tab_names_in_order = cohort.cohort_tabs.order(:order).pluck(:name)
      expect(tab_names_in_order).to eq(
        ['Active Clients', 'Matched', 'Housed', 'Ineligible', 'Inactive', 'Removed Clients'],
      )
    end
  end

  context 'idempotency' do
    before { create_default_tabs_for(cohort) }

    it 'aborts on second invocation without duplicating the Matched tab' do
      Rake::Task[task_name].invoke(cohort.id)
      Rake::Task[task_name].reenable
      expect { Rake::Task[task_name].invoke(cohort.id) }.to raise_error(SystemExit)
      expect(cohort.cohort_tabs.where(name: 'Matched').count).to eq(1)
    end
  end
end
