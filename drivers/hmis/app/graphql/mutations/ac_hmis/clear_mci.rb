###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::ClearMci < BaseMutation
    description 'Submit a form to create/update HUD record(s)'

    argument :input, Types::AcHmis::MciClearanceInput, required: true

    field :matches, [Types::AcHmis::MciClearanceMatch], null: true

    MATCH_THRESHOLD = 80
    AUTO_CLEAR_THRESHOLD = 97

    def resolve(input:)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: 'MCI connection is not configured' unless HmisExternalApis::Mci.enabled?
      return { errors: errors } if errors.any?

      mci = HmisExternalApis::Mci.new

      begin
        response = mci.clearance(input.to_client)
      rescue StandardError => e
        errors.add :base, :server_error, full_message: e.message
        return { errors: errors }
      end

      # Sort by match score, and drop any matches below 80
      mci_matches = response.
        filter { |m| m.score >= MATCH_THRESHOLD }.
        sort_by { |m| [-m.score, m.mci_id] }

      # Auto-clearance: if any match is above >97, drop all other matches
      mci_matches = [mci_matches.first] if !mci_matches.empty? && mci_matches.first.score >= AUTO_CLEAR_THRESHOLD

      # Transform to GraphQL type
      # gql_matches = mci_matches.map { |m| Types::AcHmis::MciClearanceMatch.from_mci_clearance_result(m) }

      {
        matches: mci_matches,
        errors: [],
      }
    end
  end
end
