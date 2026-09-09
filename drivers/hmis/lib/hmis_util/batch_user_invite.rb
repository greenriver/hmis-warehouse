###
# Copyright Green River Data Group, Inc.
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
    def self.invite_users!(users, dry_run: true, skip_invitation: false)
      existing_users = User.pluck(:email)
      agency_by_name = Agency.all.index_by(&:name)
      invited_by = User.system_user
      users.each do |first_name, last_name, agency_name, email|
        cleaned_email = email.downcase.strip
        if existing_users.include?(cleaned_email)
          puts "Skipping #{cleaned_email}, already has account"
          next
        end

        agency = agency_by_name[agency_name]
        agency ||= Agency.where(name: agency_name).first_or_create!
        puts "#{dry_run ? '' : 'Inviting user:'} #{first_name} #{last_name}, Agency: #{agency.name}, Email: #{cleaned_email}"
        attributes = { first_name: first_name, last_name: last_name, email: cleaned_email, agency_id: agency.id }

        next if dry_run

        User.invite!(attributes, invited_by) do |u|
          u.skip_invitation = skip_invitation
        end
      end
    end

    # Emails HMIS users whose account was created with skip_invitation and never activated.
    #
    # HmisUtil::BatchUserInvite.send_pending_invitations(dry_run: true)
    def self.send_pending_invitations(dry_run: true)
      invited_by = User.system_user
      pending_hmis_users.order(:email).to_a.each do |user|
        puts "#{dry_run ? '' : 'Inviting user:'} #{user.name}, Email: #{user.email}"
        next if dry_run

        # The instance-level invite! resets invitation_created_at, which invitation_due_at is
        # computed from; deliver_invitation alone would send a link that may already be expired.
        user.invite!(invited_by)
        puts "Failed to invite #{user.email}: #{user.errors.full_messages.to_sentence}" if user.errors.any?
      end
    end

    def self.pending_hmis_users
      User.hmis_users.not_system.
        where(invitation_sent_at: nil, invitation_accepted_at: nil).
        where.not(invitation_token: nil)
    end
    private_class_method :pending_hmis_users
  end
end
