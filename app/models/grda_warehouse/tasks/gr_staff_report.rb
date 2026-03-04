###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    # Reports active user accounts with "@greenriver" emails to Slack
    # Also reports a count (never the emails) of active accounts with personal email domains for review.
    # This is intended to be run as-needed until we are migrated to IDP system where we can manage internal user accounts.
    class GrStaffReport
      include NotifierConfig

      MAX_GR_EMAILS = 50

      def self.run!
        new.run!
      end

      def run!
        message = build_account_summary_message
        Rails.logger.info(message)
        self.class.send_single_notification(message, 'GrStaffReport')
      end

      private

      def build_account_summary_message
        gr_users = active_gr_staff_users
        personal_count = personal_email_account_count

        lines = ['GR Staff User Account Report']
        lines << format_gr_section(gr_users)
        lines << format_personal_section(personal_count)
        lines.compact.join("\n\n")
      end

      def active_gr_staff_users
        User.active.where(User.arel_table[:email].matches('%@greenriver%')).order(:email)
      end

      def format_gr_section(relation)
        count = relation.count
        truncated = count > MAX_GR_EMAILS
        emails = relation.pluck(:email)
        emails = emails.first(MAX_GR_EMAILS) if truncated

        list = emails.join(', ')
        suffix = truncated ? " (list truncated at #{MAX_GR_EMAILS} accounts; total count: #{count})" : ''
        "Found #{count} active accounts with greenriver emails: #{list.presence || '(none)'}#{suffix}"
      end

      def personal_email_account_count
        domains = ['gmail', 'googlemail', 'yahoo', 'outlook', 'hotmail', 'live', 'icloud']
        domain_conditions = domains.map { |str| User.arel_table[:email].matches("%@#{str}%") }.reduce(:or)
        User.active.where(domain_conditions).count
      end

      def format_personal_section(count)
        "Found #{count} active accounts with personal email domains (gmail, etc.) that may need review."
      end
    end
  end
end
