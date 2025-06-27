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
    field :client_id, ID, null: false
    field :client, HmisSchema::Client, null: true, description: 'Null if the user lacks permission to view the client'
    field :priority_score, Integer, null: false
    field :enrollments, HmisSchema::CeReferralSourceEnrollment.array_page_type, null: false

    def client
      load_ar_scope(scope: Hmis::Hud::Client.viewable_by(current_user), id: object.client_id)
    end

    def enrollments # not for batch
      form_definition_identifiers = object.candidate_pool.relevant_form_definition_identifiers

      # For now, resolve all current and historical enrollments for this client (including open, exited, and wip).
      # Resolve broad scope because candidate pool calculation takes into account all of these enrollments,
      # so it's possible that someone is eligible based on an old exited enrollment.
      # In the future, we may want to limit this scope (possibly based on a configuration),
      # but ideally this scope should align with the scope of enrollments used for candidate pool membership evaluation.
      # TODO(#7671) - adjust this to fetch all enrollments from all clients

      # For now, filter enrollments to those viewable by the current user.
      # In the future we may need to update this to support resolving enrollments that are NOT viewable to the current user.
      base_scope = object.client.enrollments.viewable_by(current_user)

      # float those with a relevant assessment to the top.
      with_assessment_ids = base_scope.joins(custom_assessments: :definition).
        where(definition: { identifier: form_definition_identifiers }).pluck(:id).uniq

      with_assessment = base_scope.where(id: with_assessment_ids).sort_by_option(:most_recent)
      others = base_scope.where.not(id: with_assessment_ids).sort_by_option(:most_recent)

      (with_assessment + others).
        map do |enrollment|
        OpenStruct.new(
          enrollment: enrollment,
          definition_identifiers: form_definition_identifiers,
        )
      end
    end
  end
end
