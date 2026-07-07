###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::CohortTab, type: :model do
  let(:cohort) { create :cohort }
  let(:tab) { create :cohort_tab, cohort: cohort }

  describe 'Default tabs generate expected SQL' do
    it 'active query matches' do
      query = <<~SQL
        (("cohort_clients"."destination" IS NULL OR "cohort_clients"."destination" = '') OR "cohort_clients"."housed_date" IS NULL) AND ("cohort_clients"."ineligible" IS NULL OR "cohort_clients"."ineligible" = FALSE) AND "cohort_clients"."active" = TRUE
      SQL
      rule = tab.class.default_rules.detect { |r| r[:name] == 'Active Clients' }
      expect(tab.rule_query(nil, rule[:rules]).to_sql).to eq(query.strip)
    end

    it 'housed query matches' do
      query = <<~SQL
        "cohort_clients"."housed_date" IS NOT NULL AND "cohort_clients"."destination" IS NOT NULL AND "cohort_clients"."destination" != ''
      SQL
      rule = tab.class.default_rules.detect { |r| r[:name] == 'Housed' }
      expect(tab.rule_query(nil, rule[:rules]).to_sql).to eq(query.strip)
    end

    it 'ineligible query matches' do
      query = <<~SQL
        "cohort_clients"."ineligible" = TRUE AND ("cohort_clients"."housed_date" IS NULL OR ("cohort_clients"."destination" IS NULL OR "cohort_clients"."destination" = ''))
      SQL
      rule = tab.class.default_rules.detect { |r| r[:name] == 'Ineligible' }
      expect(tab.rule_query(nil, rule[:rules]).to_sql).to eq(query.strip)
    end

    it 'inactive query matches' do
      query = '"cohort_clients"."active" = FALSE'
      rule = tab.class.default_rules.detect { |r| r[:name] == 'Inactive' }
      expect(tab.rule_query(nil, rule[:rules]).to_sql).to eq(query.strip)
    end
  end

  describe 'NOT operator' do
    it 'generates NOT COALESCE SQL for a simple not rule' do
      rule = {
        'operator' => 'not',
        'operand' => {
          'column' => 'active',
          'operator' => '==',
          'value' => true,
        },
      }
      expect(tab.rule_query(nil, rule).to_sql).to eq(
        'NOT (COALESCE(("cohort_clients"."active" = TRUE), FALSE))',
      )
    end

    it 'generates correct NOT COALESCE SQL for a compound not rule' do
      rule = {
        'operator' => 'not',
        'operand' => {
          'operator' => 'and',
          'left' => { 'column' => 'user_boolean_1', 'operator' => '==', 'value' => true },
          'right' => { 'column' => 'user_string_1', 'operator' => '<>', 'value' => nil },
        },
      }
      expect(tab.rule_query(nil, rule).to_sql).to eq(
        'NOT (COALESCE(("cohort_clients"."user_boolean_1" = TRUE AND "cohort_clients"."user_string_1" IS NOT NULL AND "cohort_clients"."user_string_1" != \'\'), FALSE))',
      )
    end

    it 'raises for unknown operators' do
      rule = { 'operator' => 'xor', 'left' => {}, 'right' => {} }
      expect { tab.rule_query(nil, rule) }.to raise_error(RuntimeError, /Unknown Operator/)
    end
  end
end
