###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AcHmis::ClearMci < BaseMutation
    description 'Perform MCI clearance and return matches'

    argument :input, Types::AcHmis::MciClearanceInput, required: true

    field :matches, [Types::AcHmis::MciClearanceMatch], null: true

    # Use a lower threshold in development so we're more likely to get matches back
    MATCH_THRESHOLD = Rails.env.development? ? 60 : 80
    AUTO_CLEAR_THRESHOLD = 97

    def resolve(input:)
      errors = HmisErrors::Errors.new
      errors.add :base, :server_error, full_message: 'MCI connection is not configured' unless HmisExternalApis::AcHmis::Mci.enabled?
      return { errors: errors } if errors.any?

      mci = HmisExternalApis::AcHmis::Mci.new
      response = mci.clearance(input.to_client)

      # Sort by match score, and drop any matches below 80
      mci_matches = response.
        filter { |m| m.score >= MATCH_THRESHOLD }.
        # If score is the same, secondary sort prefers clients that already exist in HMIS
        sort_by { |m| [-m.score, m.existing_client_id&.to_i || Float::INFINITY, m.mci_id] }

      # Auto-clearance: if any match is above >97, drop all other matches
      mci_matches = [mci_matches.first] if !mci_matches.empty? && mci_matches.first.score >= AUTO_CLEAR_THRESHOLD

      {
        matches: mci_matches,
        errors: [],
      }
    end
  end
end
