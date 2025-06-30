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
    field :client_name, String, null: false, description: 'Masked as "Candidate 123" unless the user has permission to view'
    field :priority_score, Integer, null: false
    field :enrollments, HmisSchema::CeReferralSourceEnrollment.array_page_type, null: false

    def client_name
      # todo @martha - spec test for this
      # Current permission logic: "For this destination client, are there any source clients you can view?"
      # In the future, we want to check permissions more broadly across data sources:
      # "Find all source clients, and if you have any HMIS access or warehouse access to any of them
      # (even if not in the current data source that you're logged into), then show the client name."

      # todo @martha - need to check permission on ANY, not just FIRST source client
      if source_clients.any? && current_permission?(permission: :can_view_client_name, entity: source_clients.first)
        client.brief_name
      else
        "Candidate #{object.id}"
      end
    end

    # todo @Martha - need to spec/check the changes in this method
    def enrollments # not for batch
      # Find any "relevant" Forms, meaning forms that collect Custom Data Elements that are used for eligibility or prioritization of this candidate pool. There may not be any associated forms, if eligibility is determined by other factors.
      form_definition_identifiers = object.candidate_pool.relevant_form_definition_identifiers

      # For now, resolve all current and historical enrollments for the source client(s) (including open, exited, and wip).
      # Resolve broad scope because candidate pool calculation takes into account all of these enrollments,
      # so it's possible that someone is eligible based on an old exited enrollment.
      # In the future, we may want to limit this scope (possibly based on a configuration),
      # but ideally this scope should align with the scope of enrollments used for candidate pool membership evaluation.

      # For now, filter enrollments to those viewable by the current user.
      # In the future we may need to update this to support resolving enrollments that are NOT viewable to the current user.
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

    def source_clients
      client_proxy = load_ar_association(object, :client_proxy)
      destination_client = load_ar_scope(scope: GrdaWarehouse::Hud::Client.all, id: client_proxy.client_id)
      load_ar_association(destination_client, :source_clients).viewable_by(current_user) # todo @martha - n+1
    end
  end
end
