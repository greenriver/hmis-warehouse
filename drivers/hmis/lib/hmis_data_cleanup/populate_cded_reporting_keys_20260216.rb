# frozen_string_literal: true

# One-time task queued on deploy using TaskQueue to populate reporting_keys for CDEDs.
# Finds all CDEDs with null reporting_key and attempts to generate a valid, unique reporting_key based on the key.
# If generation fails, the CDED is skipped and logged to slack/sentry for manual cleanup.
# To run manually from rails console: HmisDataCleanup::PopulateCdedReportingKeys20260216.populate!
module HmisDataCleanup
  class PopulateCdedReportingKeys20260216
    include NotifierConfig

    def self.populate!
      new.populate!
    end

    def populate!
      return unless HmisEnforcement.hmis_enabled?

      updated_count = 0
      skipped = []
      total_processed = 0

      Hmis::Hud::CustomDataElementDefinition.where(reporting_key: nil).find_each do |cded|
        total_processed += 1

        begin
          cded.reporting_key = Hmis::Form::CustomDataElementGenerator.generate_reporting_key(cded.key, owner_type: cded.owner_type)
          cded.save!
          updated_count += 1
        rescue RuntimeError, ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
          # Capture any errors: unique key generation failed, validation failed, or database constraint violation
          skipped << { id: cded.id, key: cded.key, owner_type: cded.owner_type, reason: e.message }
        end
      end

      # Build summary message
      summary = {
        updated: updated_count,
        skipped: skipped.count,
        total_processed: total_processed,
      }

      summary_message = <<~MSG
        CDED Reporting Key Population Complete

        Updated: #{summary[:updated]}
        Skipped: #{summary[:skipped]}
        Total processed: #{summary[:total_processed]}
      MSG

      Rails.logger.info(summary_message)

      # Send to Slack via notifier
      send_single_notification(summary_message, 'PopulateCdedReportingKeys')

      # Report failures to Sentry if any
      return unless skipped.any?

      Sentry.capture_message(
        'CustomDataElementDefinition CDED reporting_key population was unable to update all CDEDs',
        level: :warning,
        extra: skipped,
      )
    end
  end
end
