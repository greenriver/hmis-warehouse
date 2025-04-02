
# frozen_string_literal: true

class CreateAnalyticsCeOpportunityCategories < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.ce_opportunity_categories'

    create_view 'analytics.ce_opportunities'
    create_view 'analytics.ce_clients'
    create_view 'analytics.ce_workflow_contacts'
    create_view 'analytics.ce_cas_users'
    create_view 'analytics.ce_workflows'
    create_view 'analytics.ce_steps'
    create_view 'analytics.ce_workflow_users'

  end
end
