###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::CalculateClientEligibility < CleanBaseMutation
    description 'Calculate client eligibility based on provided assessment values and return applicable project types'

    argument :enrollment_id, ID, required: true
    argument :form_definition_identifier, String, required: true
    argument :values_by_link_id, Types::JsonObject, required: true

    field :project_types, [Types::HmisSchema::Enums::ProjectType], null: false

    def resolve(enrollment_id:, form_definition_identifier:, values_by_link_id:)
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find(enrollment_id)
      access_denied! unless current_user.can_edit_enrollments_for?(enrollment)

      client = enrollment.client.destination_client
      return { project_types: [] } unless client

      # Convert form values to field value overrides for CE evaluation
      overrides = build_overrides(values_by_link_id, form_definition_identifier)

      # Get all candidate pools and evaluate client eligibility
      eligible_project_types = calculate_eligible_project_types(client, overrides)

      { project_types: eligible_project_types }
    end

    private

    def build_overrides(values_by_link_id, form_definition_identifier)
      # Get the form definition to understand the mapping from link_ids to custom field keys
      form_definition = Hmis::Form::Definition.published.find_by(identifier: form_definition_identifier)
      return {} unless form_definition

      # Build overrides hash by mapping form values to CE field format
      values_by_link_id.filter_map do |link_id, value|
        form_item = form_definition.link_id_item_hash[link_id]
        custom_field_key = form_item&.dig('mapping', 'custom_field_key')
        next unless custom_field_key

        # Map to CDE field format for CE evaluation
        ["cde.custom_assessment.#{custom_field_key}", value]
      end.to_h
    end

    def calculate_eligible_project_types(client, field_value_overrides)
      field_map = Hmis::Ce::Match::Expression::FieldMap.new(current_date: Date.current)
      eligible_pools = []

      # Evaluate client against all (not just active) candidate pools
      Hmis::Ce::Match::CandidatePool.find_each do |pool|
        clients = GrdaWarehouse::Hud::Client.where(id: client.id)
        evaluator = Hmis::Ce::Match::Internal::ClientPoolEvaluator.new(clients, pool, field_map)
        result = evaluator.call(client, field_value_overrides: field_value_overrides)

        eligible_pools << pool unless result.failed?
      end

      # Find projects that use the eligible pools and collect their project types
      project_types = find_project_types_from_pools(eligible_pools)
      project_types.uniq
    end

    def find_project_types_from_pools(pools)
      return [] if pools.empty?

      # Get project types from Unit Groups that use these pools.
      # (Unit Groups and not Opportunities, because we want to return results about what projects the client is eligible for, regardless of availability)
      Hmis::UnitGroup.
        joins(:project).
        where(candidate_pool_id: pools.map(&:id)).
        pluck('Project.project_type').
        compact.uniq
    end
  end
end
