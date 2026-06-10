###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class BatchUserInvite
    # The "users" shape is meant to be easily copied from a spreadsheet.
    # Make sure that the Agency name exactly matches an Agency record's name,
    # if you wish to match to existing agencies.
    #
    # users = [['First', 'Last', 'Sample Agency', 'example@greenriver.org',]]
    # HmisUtil::BatchUserInvite.invite_users!(users, dry_run: true)
    # TODO: Add Keycloak setup-email support
    def self.invite_users!(users, dry_run: true, skip_invitation: false) # rubocop:disable Lint/UnusedMethodArgument
      existing_users = User.pluck(:email)
      agency_by_name = Agency.all.index_by(&:name)
      users.each do |first_name, last_name, agency_name, email|
        cleaned_email = email.downcase.strip
        if existing_users.include?(cleaned_email)
          puts "Skipping #{cleaned_email}, already has account"
          next
        end

        agency = agency_by_name[agency_name]
        agency ||= Agency.where(name: agency_name).first_or_create!
        puts "#{dry_run ? '' : 'Creating user:'} #{first_name} #{last_name}, Agency: #{agency.name}, Email: #{cleaned_email}"

        next if dry_run

        User.create!(
          first_name: first_name,
          last_name: last_name,
          email: cleaned_email,
          agency_id: agency.id,
          confirmed_at: Time.current,
        )
      end
    end
  end
end
