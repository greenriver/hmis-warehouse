# frozen_string_literal: true

class CreateCeReferralAnalyticsViews < ActiveRecord::Migration[7.2]
  def change
    create_view 'analytics.ce_workflow_templates'
    create_view 'analytics.ce_custom_referral_statuses'
    create_view 'analytics.ce_opportunities'
    create_view 'analytics.ce_referrals'
    create_view 'analytics.ce_referral_notes'
    create_view 'analytics.ce_referral_step_assignments'
    create_view 'analytics.ce_referral_participants'
    create_view 'analytics.ce_referral_steps'
  end
end
