# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_match_candidate_pool, class: 'Hmis::Ce::Match::CandidatePool' do
    requirement_expression { 'TRUE' }
    # Use a sequence because candidate pools have a uniqueness constraint on requirement + priority
    sequence(:priority_expression) { |n| "{#{n}}" }
  end

  # Helper factory for creating a candidate pool that is considered active:
  # - tied to a unit group
  # - unit group is in a project that supports waitlist-based referrals
  #
  # Caution: When using this factory, the unit group's after_create callback will overwrite the candidate_pool back to nil if there are no applicable rules.
  # Work around this by stubbing the CandidatePoolBuilder in tests that don't need to test its behavior:
  # allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
  factory :hmis_ce_match_candidate_pool_active_with_unit_group, parent: :hmis_ce_match_candidate_pool do
    transient do
      data_source { create(:hmis_data_source) }
      project { create(:hmis_hud_project, data_source: data_source) }
    end

    after(:create) do |pool, evaluator|
      create(:hmis_project_ce_config, project: evaluator.project, supports_waitlist_referrals: true)
      create(:hmis_unit_group, project: evaluator.project, candidate_pool: pool)
    end
  end

  factory :hmis_ce_match_candidate_pool_with_candidates, parent: :hmis_ce_match_candidate_pool do
    transient do
      client_count { nil }
      client_proxies { nil }
      destination_clients { nil }
    end

    after(:create) do |pool, evaluator|
      if evaluator.client_count
        create_list(:hmis_ce_client_proxy, evaluator.client_count, candidate_pool: pool) do |client_proxy|
          create(:hmis_ce_match_candidate, client_proxy: client_proxy, candidate_pool: pool)
        end
      elsif evaluator.client_proxies
        evaluator.client_proxies.each do |client_proxy|
          create(:hmis_ce_match_candidate, client_proxy: client_proxy, candidate_pool: pool)
        end
      elsif evaluator.destination_clients
        evaluator.destination_clients.each do |destination_client|
          client_proxy = create(:hmis_ce_client_proxy, client: destination_client, candidate_pool: pool)
          create(:hmis_ce_match_candidate, client_proxy: client_proxy, candidate_pool: pool)
        end
      end
    end
  end
end
