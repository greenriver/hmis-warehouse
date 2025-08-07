###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Determines a user's permissions for CE Opportunities
class Hmis::AuthPolicies::CeOpportunityPolicy < Hmis::AuthPolicies::BasePolicy
  # Accepts client parameter because referral authorization requires validating
  # the relationship between three entities: user, opportunity, and client.
  def can_create_referral?(client:)
    return false unless Hmis::Ce.configuration.enabled?

    # Does the client record data source match the current user?
    return false unless client.data_source_id == user.hmis_data_source_id

    # Does the user have permission?
    return false unless context.project_permissions(opportunity.project_id).include?(:can_start_referrals)

    true
  end

  def can_view_candidates?
    context.project_permissions(opportunity.project_id).include?(:can_view_prioritized_client_lists)
  end

  protected

  def opportunity = resource
  def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Ce::Opportunity)
end
