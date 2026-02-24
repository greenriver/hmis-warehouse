###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CalculateClientCeEligibility < CleanBaseMutation
    # Calculates provisional client eligibility, based on the form values provided.
    # Does not result in the client actually becoming a Candidate for any opportunities.
    # Does not mutate data. Implemented as a mutation in order to use CleanBaseMutation's validation error pattern.

    description 'Calculate client eligibility based on provided assessment values and return applicable project types'

    argument :enrollment_id, ID, required: true
    argument :form_definition_id, ID, required: true
    argument :values_by_link_id, Types::JsonObject, required: true

    field :project_types, [Types::HmisSchema::Enums::ProjectType], null: true

    def resolve(enrollment_id:, form_definition_id:, values_by_link_id:)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find(enrollment_id)
      access_denied! unless policy_for(enrollment, policy_type: :hmis_enrollment).can_edit?

      # The match engine expects destination clients
      client = enrollment.client.destination_client
      unless client
        errors = HmisErrors::Errors.new
        errors.add :base, :invalid, full_message: 'Unable to calculate eligibility because client background processing has not finished yet. Please try again later.'
        return { errors: errors }
      end

      # Convert form values to field value overrides for CE evaluation
      overrides = build_overrides(values_by_link_id, form_definition_id)

      # Get evaluate client eligibility against all candidate pools
      eligible_project_types = calculate_eligible_project_types(client, overrides)

      { project_types: eligible_project_types }
    end

    private

    ALWAYS_OVERRIDE = {
      # Custom fields that should always be overridden when calculating provisional client eligibility. (#8129)
      'cde.custom_assessment.housing_needs_post_referrals_to_waitlist': 'Yes',
    }.stringify_keys.freeze

    def build_overrides(values_by_link_id, form_definition_id)
      # Get the form definition to map from link_id to custom_field_key
      form_definition = Hmis::Form::Definition.find(form_definition_id)

      # Build overrides hash. Note that values_by_link_id does not include hidden fields.
      overrides = values_by_link_id.filter_map do |link_id, value|
        form_item = form_definition.link_id_item_hash[link_id]
        custom_field_key = form_item&.dig('mapping', 'custom_field_key')
        next unless custom_field_key

        # Map to CDE field format for CE evaluation - see FieldMap
        ["cde.custom_assessment.#{custom_field_key}", value]
      end.to_h

      # Add assessment metadata overrides, because for the purposes of calculating what opportunities the client *would* be eligible for given the form values, we should also pretend they've had a real form submitted
      overrides["custom_assessment.#{form_definition.identifier}.date_created"] = Time.current
      overrides["custom_assessment.#{form_definition.identifier}.date_updated"] = Time.current
      overrides["custom_assessment.#{form_definition.identifier}.assessment_date"] = Date.current

      overrides.merge(ALWAYS_OVERRIDE)
    end

    def calculate_eligible_project_types(client, field_value_overrides)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new(current_date: Date.current)
      eligible_pools = []
      clients = GrdaWarehouse::Hud::Client.where(id: client.id)

      Hmis::Ce::Match::CandidatePool.active.find_each do |pool|
        evaluator = Hmis::Ce::Match::Internal::ClientPoolEvaluator.new(clients, pool, field_map)
        result = evaluator.call(client, field_value_overrides: field_value_overrides)

        eligible_pools << pool unless result.failed? # result fails if client is ineligible
      end

      # Find projects that use the eligible pools and collect their project types
      project_types = find_project_types_from_pools(eligible_pools)
      project_types.uniq
    end

    def find_project_types_from_pools(pools)
      return [] if pools.empty?

      # Get project types from Unit Groups that use these pools.
      # (Unit Groups and not Opportunities, because we want to return results about what projects the client is eligible for, regardless of availability)
      Hmis::Hud::Project.
        with_ce_waitlists_enabled.
        joins(:unit_groups).
        merge(Hmis::UnitGroup.where(candidate_pool_id: pools.map(&:id))).
        distinct.
        pluck(:project_type)
    end
  end
end
