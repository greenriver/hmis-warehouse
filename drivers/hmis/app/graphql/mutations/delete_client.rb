###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteClient < BaseMutation
    argument :id, ID, required: true
    argument :confirmed, Boolean, 'Whether warnings have been confirmed', required: false

    field :client, Types::HmisSchema::Client, null: true

    def resolve(id:, confirmed: false)
      client = Hmis::Hud::Client.find_by(id: id)

      warnings, resolvable_enrollments = check_enrollments(client, ignore_warnings: confirmed)

      return { client: nil, errors: warnings } if warnings.present?

      default_delete_record(
        record: client,
        field_name: :client,
        permissions: :can_delete_clients,
        after_delete: -> do
          resolvable_enrollments.each do |enrollment|
            enrollment.household_members.where.not(personal_id: client.personal_id).first&.update!(relationship_to_ho_h: 1)
          end
        end,
      )
    end

    def check_enrollments(client, ignore_warnings: false)
      problem_enrollments = []
      warnings = []
      resolvable_enrollments = []

      client.enrollments.each do |enrollment|
        next unless enrollment.relationship_to_ho_h == 1

        members = enrollment.household_members

        problem_enrollments << enrollment if members.count > 2
        resolvable_enrollments << enrollment if members.count == 2
      end

      if problem_enrollments.present? && !ignore_warnings
        warnings << HmisErrors::Error.new(
          :id,
          :information,
          full_message: "If this client is deleted, #{problem_enrollments.size} households will have no Head of Household.",
          severity: :warning,
          data: {
            text: 'The Head of Household for the following households should be changed:',
            enrollments: problem_enrollments.map do |e|
              {
                id: e.id.to_s,
                name: e.project&.project_name,
                entryDate: e.entry_date,
                exitDate: e.exit_date,
              }
            end,
            confirmText: 'Delete client anyway',
          },
        )
      end

      [
        warnings,
        resolvable_enrollments,
      ]
    end
  end
end
