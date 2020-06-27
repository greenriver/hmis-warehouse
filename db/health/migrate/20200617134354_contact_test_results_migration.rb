class ContactTestResultsMigration < ActiveRecord::Migration[5.2]
  def up
    Health::Tracing::Contact.with_deleted.each do |contact|
      result = contact.results.build
      result.assign_attributes(
        test_result: contact.test_result,
        isolated: contact.isolated,
        isolation_location: contact.isolation_location,
        quarantine: contact.quarantine,
        quarantine_location: contact.quarantine_location,
        deleted_at: contact.deleted_at,
      )
      result.save if live?(result)
    end
  end

  def down
    Health::Tracing::Result.with_deleted.delete_all
  end

  def live?(result)
    result.test_result.present? ||
      result.isolated.present? || result.isolation_location.present? ||
      result.quarantine.present? || result.quarantine_location.present?
  end
end
