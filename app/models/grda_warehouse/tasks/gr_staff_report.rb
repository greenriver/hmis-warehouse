###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    # Reports active user accounts with "@greenriver" emails and a count of personal-email accounts.
    # When S3 app_stats is configured (same bucket as AppResourceMonitor::CollectStatsJob), uploads
    # the full report there so all contents are centralized. Otherwise reports GR emails to Slack.
    # This is intended to be run as-needed until we are migrated to IDP system where we can manage internal user accounts.
    #
    # Usage: GrdaWarehouse::Tasks::GrStaffReport.run!
    class GrStaffReport
      include NotifierConfig

      MAX_GR_EMAILS = 50
      S3_SLUG = 'app_stats'

      def self.run!(upload_to_s3: true)
        new.run!(upload_to_s3: upload_to_s3)
      end

      def run!(upload_to_s3: true)
        if s3_config.present? && upload_to_s3
          upload_report_to_s3
        else
          send_slack_summary
        end
      end

      private

      def s3_config
        @s3_config ||= GrdaWarehouse::RemoteCredentials::S3.active.where(slug: S3_SLUG).first
      end

      # Prefix filename with client and environment for identification.
      def file_prefix
        [ENV.fetch('CLIENT', nil), Rails.env].compact.map(&:to_s).map(&:strip).join('-')
      end

      def build_account_summary_message
        gr_users = active_gr_staff_users
        personal_count = personal_email_account_count

        lines = ['GR Staff User Account Report']
        lines << format_gr_section(gr_users)
        lines << format_personal_section(personal_count)
        lines.compact.join("\n\n")
      end

      def upload_report_to_s3
        content = build_account_summary_message
        Rails.logger.info(content)
        # Place in new 'gr_staff_report' dir directly in bucket, not in app_resource_monitor dir to avoid cluttering it
        key = "gr_staff_report/#{Time.current.to_fs(:number)}-#{file_prefix}-gr-staff-report.txt"
        s3_config.s3.store(content: content, name: key, content_type: 'text/plain')
        send_single_notification("GrStaffReport uploaded to S3: #{key}", 'GrStaffReport')
      end

      def send_slack_summary
        message = build_account_summary_message
        Rails.logger.info(message)
        send_single_notification(message, 'GrStaffReport')
      end

      def active_gr_staff_users
        User.active.where(User.arel_table[:email].matches('%@greenriver%')).order(:email)
      end

      def format_gr_section(relation)
        count = relation.count
        truncated = count > MAX_GR_EMAILS
        emails = if truncated
          relation.limit(MAX_GR_EMAILS).pluck(:email)
        else
          relation.pluck(:email)
        end

        list = emails.join("\n")
        suffix = truncated ? "\n(list truncated at #{MAX_GR_EMAILS} accounts; total count: #{count})" : ''
        "Found #{count} active accounts with greenriver emails:\n#{list.presence || '(none)'}#{suffix}"
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
