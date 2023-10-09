###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisUtil
  class BatchUserInvite
    # The "users" shape is meant to be easily copied from a spreadsheet.
    # Make sure that the Agency name exactly matches an Agency record's name.
    # This DOES send out invitations to users.
    #
    # users = [['Sample Agency', 'First Last', 'example@greenriver.org']]
    # HmisUtil::BatchUserInvite.invite_users!(users, dry_run: true)
    def self.invite_users!(users, dry_run: true, skip_invitation: false)
      existing_users = User.pluck(:email)
      agency_by_name = Agency.all.index_by(&:name)
      invited_by = User.system_user
      users.each do |agency_name, name, email|
        if existing_users.include?(email.downcase)
          puts "Skipping #{email}, already has account"
          next
        end

        agency = agency_by_name[agency_name]
        unless agency
          puts "Skipping #{email}, agency '#{agency_name}' does not exist."
          next
        end
        first_name = name.split.first
        last_name = name.split[1..].join(' ') if name.split.count > 1

        puts "#{dry_run ? '' : 'Inviting user:'} FIRST:#{first_name}, LAST:#{last_name}, AGENCY:#{agency.name}, EMAIL:#{email}"
        attributes = { first_name: first_name, last_name: last_name, email: email.downcase, agency_id: agency.id }

        next if dry_run

        User.invite!(attributes, invited_by) do |u|
          u.skip_invitation = skip_invitation
        end
      end
    end
  end
end
