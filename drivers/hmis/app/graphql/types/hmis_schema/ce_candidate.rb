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

      # TODO(#7671) - adjust this to fetch all enrollments from all clients
      object.client.enrollments.
        viewable_by(current_user). # For now, filter enrollments to those viewable by the current user. Future workflows may require more access.
        sort_by_option(:most_recent).
        map do |enrollment|
        OpenStruct.new(
          enrollment: enrollment,
          definition_identifiers: form_definition_identifiers,
        )
      end
    end
  end
end
