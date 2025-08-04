###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidate < Types::BaseObject
    # object is a Hmis::Ce::Match::Candidate
    field :id, ID, null: false
    field :destination_client_id, ID, null: false
    field :client_name, String, null: false, description: 'Masked as "Candidate 123" unless the user has permission to view'
    field :priority_score, Integer, null: false, deprecation_reason: 'Replaced by priorityScores'
    field :priority_scores, [Integer], null: false, default_value: [0]
    field :enrollments, HmisSchema::CeReferralSourceEnrollment.array_page_type, null: false

    # TODO(#7957) - remove after deprecation period
    def priority_score
      priority_scores&.first || 0
    end

    # todo @martha - display priority scores correctly in UI

    def destination_client_id
      destination_client.id
    end

    def client_name
      # For this destination client, are there any source clients whose names you can view? If so, return the first viewable name.
      # In the future, we want to check permissions more broadly across data sources. (viewable_by scope only accounts for permissions in current data source.)

      # Iterate through source clients avoids n+1 issues with viewable_by scope
      first_viewable_name = source_clients.sort_by(&:id).find do |client|
        current_permission?(permission: :can_view_clients, entity: client) && current_permission?(permission: :can_view_client_name, entity: client)
      end&.brief_name

      first_viewable_name || "Candidate #{object.id}"
    end

    def enrollments # not for batch
      # Find any "relevant" Forms, meaning forms that collect Custom Data Elements that are used for eligibility or prioritization of this candidate pool. There may not be any associated forms, if eligibility is determined by other factors.
      form_definition_identifiers = object.candidate_pool.relevant_form_definition_identifiers

      # For now, resolve all current and historical enrollments for the source client(s) (including open, exited, and wip).
      # Resolve broad scope because candidate pool calculation takes into account all of these enrollments,
      # so it's possible that someone is eligible based on an old exited enrollment.
      # In the future, we may want to limit this scope (possibly based on a configuration),
      # but ideally this scope should align with the scope of enrollments used for candidate pool membership evaluation.

      # For now, filter enrollments to those viewable by the current user.
      # In the future we may need to update this to support resolving enrollments that are NOT viewable to the current user (#7891)
      base_scope = Hmis::Hud::Enrollment.viewable_by(current_user).where(client: source_clients)

      # Source Enrollment IDs that should be prioritized because they are the enrollment(s) where the most recently updated
      # Eligibility/Prioritization Assessment was taken for this client
      prioritized_enrollment_ids = Hmis::Hud::CustomAssessment.where(client: source_clients).
        with_form_definition_identifier(form_definition_identifiers).
        preload(:definition, :enrollment).
        group_by { |a| a.definition.identifier }.
        transform_values do |assessments|
          most_recent = assessments.max_by(&:DateUpdated)
          most_recent.enrollment.id
        end.values

      prioritized = base_scope.where(id: prioritized_enrollment_ids).sort_by_option(:most_recent)
      others = base_scope.where.not(id: prioritized_enrollment_ids).sort_by_option(:most_recent)

      (prioritized + others).
        map do |enrollment|
        OpenStruct.new(
          enrollment: enrollment,
          definition_identifiers: form_definition_identifiers,
        )
      end
    end

    private

    def destination_client
      client_proxy = load_ar_association(object, :client_proxy)
      load_ar_scope(scope: GrdaWarehouse::Hud::Client.all, id: client_proxy.client_id)
    end

    def source_clients
      load_ar_association(destination_client, :hmis_source_clients)
    end
  end
end
