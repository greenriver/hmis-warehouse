# frozen_string_literal: true

class CreateAnalyticsCeOpportunityCategories < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.cas_opportunity_categories'
    create_view 'analytics.cas_opportunities'
    create_view 'analytics.cas_clients'
    create_view 'analytics.cas_referral_contacts'
    create_view 'analytics.cas_users'
    create_view 'analytics.cas_referrals'
    create_view 'analytics.cas_steps'
    create_view 'analytics.cas_referral_users'
  end
end
