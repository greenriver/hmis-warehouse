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

    def self.problem_enrollments_message(count)
      "If this client is deleted, #{count} #{'household'.pluralize(count)} will have no Head of Household."
    end

    def resolve(id:, confirmed: false)
      client = Hmis::Hud::Client.find_by(id: id)

      warnings, resolvable_enrollments = check_enrollments(client, ignore_warnings: confirmed)

      return { client: nil, errors: warnings } if warnings.any?

      client.transaction do
        default_delete_record(
          record: client,
          field_name: :client,
          permissions: :can_delete_clients,
          after_delete: -> do
            resolvable_enrollments.each do |enrollment|
              enrollment.update!(relationship_to_ho_h: 1)
            end
          end,
        )
      end
    end

    def check_enrollments(client, ignore_warnings: false)
      problem_enrollments = []
      warnings = []
      resolvable_enrollments = []

      client.enrollments.viewable_by(current_user).heads_of_households.each do |enrollment|
        members = enrollment.household_members

        problem_enrollments << enrollment if members.count > 2
        resolvable_enrollments += members.where.not(personal_id: client.personal_id) if members.count == 2
      end

      if problem_enrollments.present? && !ignore_warnings
        warnings = HmisErrors::Errors.new
        warnings.add(
          :id,
          :information,
          full_message: self.class.problem_enrollments_message(problem_enrollments.size),
          severity: :warning,
          data: {
            text: "The Head of Household for the following #{'household'.pluralize(problem_enrollments.size)} should be changed before this client is deleted:",
            enrollments: problem_enrollments.map do |e|
              {
                id: e.id.to_s,
                name: e.project&.project_name,
                entryDate: e.entry_date,
                exitDate: e.exit_date,
              }
            end,
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
