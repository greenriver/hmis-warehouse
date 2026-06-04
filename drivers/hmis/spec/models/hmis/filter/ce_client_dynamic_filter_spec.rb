# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Filter::CeClientFilter, type: :model do
  include_context 'hmis base setup'

  let(:current_date) { Date.new(2024, 12, 26) }

  let!(:form) do
    create(
      :hmis_form_definition,
      role: :CUSTOM_ASSESSMENT,
      identifier: "ceClientFilterForm#{SecureRandom.hex(4)}",
      data_source: ds1,
    )
  end

  let!(:cded_language) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'language_pref',
      field_type: :string,
      repeats: false,
      data_source: ds1,
      form_definition_identifier: form.identifier,
    )
  end

  let!(:cded_priority_score) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'priority_score',
      field_type: :integer,
      repeats: false,
      data_source: ds1,
      form_definition_identifier: form.identifier,
    )
  end

  let!(:cded_tags) do
    create(
      :hmis_custom_data_element_definition,
      owner_type: 'Hmis::Hud::CustomAssessment',
      key: 'tags',
      field_type: :string,
      repeats: true,
      data_source: ds1,
      form_definition_identifier: form.identifier,
    )
  end

  let(:key_language) { "cde.custom_assessment.#{cded_language.key}" }
  let(:key_score) { "cde.custom_assessment.#{cded_priority_score.key}" }
  let(:key_tags) { "cde.custom_assessment.#{cded_tags.key}" }

  let!(:c1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let!(:c2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let!(:c3) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }

  let!(:c1_proxy) { create(:hmis_ce_client_proxy, client: c1.destination_client) }
  let!(:c2_proxy) { create(:hmis_ce_client_proxy, client: c2.destination_client) }
  let!(:c3_proxy) { create(:hmis_ce_client_proxy, client: c3.destination_client) }

  let(:base_scope) { Hmis::Ce::ClientProxy.where(id: [c1_proxy.id, c2_proxy.id, c3_proxy.id]) }

  def build_assessment(hmis_client, assessment_date:)
    create(
      :hmis_custom_assessment,
      client: hmis_client,
      definition: form,
      data_source: ds1,
      assessment_date: assessment_date,
    )
  end

  def build_cde(assessment, cded, **value_attrs)
    create(
      :hmis_custom_data_element,
      owner: assessment,
      data_element_definition: cded,
      data_source: ds1,
      **value_attrs,
    )
  end

  before do
    # c1: latest assessment — English, score 10, repeating tags alpha/beta
    c1_assessment_older = build_assessment(c1, assessment_date: current_date - 2.weeks)
    build_cde(c1_assessment_older, cded_language, value_string: 'Spanish')
    build_cde(c1_assessment_older, cded_priority_score, value_integer: 1)
    build_cde(c1_assessment_older, cded_tags, value_string: 'theta')

    c1_assessment_latest = build_assessment(c1, assessment_date: current_date)
    build_cde(c1_assessment_latest, cded_language, value_string: 'English')
    build_cde(c1_assessment_latest, cded_priority_score, value_integer: 10)
    build_cde(c1_assessment_latest, cded_tags, value_string: 'alpha')
    build_cde(c1_assessment_latest, cded_tags, value_string: 'beta')

    # c2: French, score 20, one tag
    c2_assessment = build_assessment(c2, assessment_date: current_date - 1.day)
    build_cde(c2_assessment, cded_language, value_string: 'French')
    build_cde(c2_assessment, cded_priority_score, value_integer: 20)
    build_cde(c2_assessment, cded_tags, value_string: 'gamma')

    # c3: no assessments (no matching CDE rows)
  end

  def apply_filters(scope, dynamic_filters)
    input = OpenStruct.new(dynamic_filters: dynamic_filters, search_term: nil, project_type: nil)
    described_class.new(input).filter_scope(scope)
  end

  def dynamic_filter(key:, values:)
    OpenStruct.new(key: key, values: values)
  end

  describe '#filter_scope with dynamic_filters' do
    it 'returns clients whose latest string CDE matches a single filter value' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_language, values: ['English'])],
      )
      expect(result).to contain_exactly(c1_proxy)
    end

    it 'returns clients matching any of several string values (OR across filter values)' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_language, values: ['English', 'French'])],
      )
      expect(result).to contain_exactly(c1_proxy, c2_proxy)
    end

    it 'returns clients when integer CDEs are filtered using string values (API shape)' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_score, values: ['10', '20'])],
      )
      expect(result).to contain_exactly(c1_proxy, c2_proxy)
    end

    it 'returns clients when a single numeric filter value is stringified' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_score, values: ['10'])],
      )
      expect(result).to contain_exactly(c1_proxy)
    end

    it 'does not return clients where an older assessment matches the filter (numeric)' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_score, values: ['1'])],
      )
      expect(result).to be_empty
    end

    it 'does not return clients where an older assessment matches the filter (repeating tag)' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_score, values: ['theta'])],
      )
      expect(result).to be_empty
    end

    it 'returns clients when a repeating CDE matches if any repeated value is in the filter list' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_tags, values: ['alpha', 'delta'])],
      )
      expect(result).to contain_exactly(c1_proxy)
    end

    it 'returns clients when a repeating CDE matches a second distinct value on another client' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_tags, values: ['gamma'])],
      )
      expect(result).to contain_exactly(c2_proxy)
    end

    it 'combines multiple dynamic filters with AND semantics' do
      result = apply_filters(
        base_scope,
        [
          dynamic_filter(key: key_language, values: ['French']),
          dynamic_filter(key: key_score, values: ['20']),
        ],
      )
      expect(result).to contain_exactly(c2_proxy)
    end

    it 'returns no rows when no client matches the CDE filter' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_score, values: ['99'])],
      )
      expect(result).to be_empty
    end

    it 'returns no rows for clients without a latest assessment for that form' do
      result = apply_filters(
        base_scope,
        [dynamic_filter(key: key_language, values: ['English', 'French', 'Spanish'])],
      )
      expect(result).not_to include(c3_proxy)
      expect(result).to contain_exactly(c1_proxy, c2_proxy)
    end

    it 'skips filters whose values are all blank after normalization' do
      result = apply_filters(
        base_scope,
        [
          dynamic_filter(key: key_language, values: ['']),
          dynamic_filter(key: key_score, values: ['10']),
        ],
      )
      expect(result).to contain_exactly(c1_proxy)
    end

    it 'raises in test when more than 50 dynamic filters are supplied' do
      filters = 51.times.map do |i|
        dynamic_filter(key: key_language, values: ["nope-#{i}"])
      end
      expect do
        apply_filters(base_scope, filters)
      end.to raise_error(ArgumentError, /CE client dynamic filters limit/)
    end

    it 'raises in test when a filter key is not a cde.* expression key' do
      input = OpenStruct.new(
        dynamic_filters: [dynamic_filter(key: 'current_age', values: ['20'])],
        search_term: nil,
        project_type: nil,
      )
      expect do
        described_class.new(input).filter_scope(base_scope)
      end.to raise_error(ArgumentError, /CE client dynamic filters only support/)
    end

    describe 'performance' do
      let(:several_filters) do
        [
          dynamic_filter(key: key_language, values: ['English']),
          dynamic_filter(key: key_score, values: ['10', '15']),
          dynamic_filter(key: key_tags, values: ['alpha', 'beta']),
        ]
      end

      # Additional client proxies to be included in the base scope for testing query performance
      let!(:bulk_proxies) do
        15.times.map do
          client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1)
          proxy = create(:hmis_ce_client_proxy, client: client.destination_client)
          assessment = build_assessment(client, assessment_date: current_date)
          build_cde(assessment, cded_language, value_string: 'English')
          build_cde(assessment, cded_priority_score, value_integer: 15)
          build_cde(assessment, cded_tags, value_string: 'beta')
          proxy
        end
      end

      let(:performance_scope) do
        Hmis::Ce::ClientProxy.where(id: [c1_proxy.id, c2_proxy.id, c3_proxy.id] + bulk_proxies.map(&:id))
      end

      # Query count stays low and does not scale with client count
      it 'makes a small number of queries when loading filtered results' do
        expect do
          apply_filters(performance_scope, several_filters).to_a
        end.to make_database_queries(count: 2..10)
      end

      it 'does not use correlated EXISTS against the latest-assessment view - regression test for #9269' do
        sql = []
        callback = ->(*, payload) { sql << payload[:sql] }
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          apply_filters(performance_scope, several_filters).to_a
        end

        # Prior to #9269 fix, the code with the performance problem generated SQL like:
        # SELECT DISTINCT "ce_client_proxies"."id" FROM "ce_client_proxies" WHERE (EXISTS ( SELECT 1 FROM "hmis_destination_client_latest_assessments" ...) AND (EXISTS ( SELECT 1 FROM "hmis_destination_client_latest_assessments" ...)
        # The problem was correlated EXISTS subqueries tied to each outer row, not multiple view references per se.
        expect(sql.join).not_to match(/EXISTS.*hmis_destination_client_latest_assessments.*ce_client_proxies.*client_id/m)
      end
    end
  end
end
