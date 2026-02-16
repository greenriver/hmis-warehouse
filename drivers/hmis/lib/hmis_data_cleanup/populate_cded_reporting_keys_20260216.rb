# frozen_string_literal: true

class PopulateCdedReportingKeys20260216
  include NotifierConfig

  # Reporting key format validation regex
  REPORTING_KEY_REGEX = /\A[a-z][a-z0-9_]{0,62}\z/

  def self.populate!
    new.populate!
  end

  def populate!
    updated_count = 0
    skipped_invalid = []
    skipped_duplicate = []
    total_processed = 0

    # Find all CDEDs with null reporting_key
    Hmis::Hud::CustomDataElementDefinition.where(reporting_key: nil).find_each do |cded|
      total_processed += 1
      key = cded.key
      candidate_key = key.downcase.gsub(/[^a-z0-9_]/, '_') # attempt to normalize the key, without truncating (which may cause conflicts)

      # Check if normalized candidate_key is valid
      unless candidate_key.match?(REPORTING_KEY_REGEX)
        skipped_invalid << { id: cded.id, key: key, owner_type: cded.owner_type, reason: 'invalid_format' }
        next
      end

      # Check for uniqueness conflict
      if Hmis::Hud::CustomDataElementDefinition.
          where(owner_type: cded.owner_type, reporting_key: candidate_key).
          where.not(id: cded.id).
          exists?
        skipped_duplicate << { id: cded.id, key: key, owner_type: cded.owner_type, candidate_key: candidate_key }
        next
      end

      # Update the reporting_key
      cded.update!(reporting_key: candidate_key)
      updated_count += 1
    end

    # Build summary message
    summary = {
      updated: updated_count,
      skipped_invalid: skipped_invalid.count,
      skipped_duplicate: skipped_duplicate.count,
      total_processed: total_processed,
    }

    summary_message = <<~MSG
      CDED Reporting Key Population Complete

      Updated: #{summary[:updated]}
      Skipped (invalid): #{summary[:skipped_invalid]}
      Skipped (duplicate): #{summary[:skipped_duplicate]}
      Total processed: #{summary[:total_processed]}
    MSG

    Rails.logger.info(summary_message)

    # Send to Slack via notifier
    send_single_notification(summary_message, 'PopulateCdedReportingKeys')

    # Report failures to Sentry if any
    failed_keys = skipped_invalid + skipped_duplicate
    return unless failed_keys.any?

    error_details = {
      skipped_invalid: skipped_invalid,
      skipped_duplicate: skipped_duplicate,
    }

    Sentry.capture_message(
      'CustomDataElementDefinition CDED reporting_key population was unable to update all CDEDs',
      level: :warning,
      extra: error_details,
    )
  end
end
