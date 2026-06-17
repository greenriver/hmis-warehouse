###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Sources
  class HmisUserByEmail < ::GraphQL::Dataloader::Source
    def fetch(emails)
      users_by_email = Hmis::User.with_deleted.where(email: emails.map(&:downcase)).index_by(&:email)

      emails.map { |email| users_by_email[email.downcase] }
    end
  end
end
