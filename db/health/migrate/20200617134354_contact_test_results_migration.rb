class ContactTestResultsMigration < ActiveRecord::Migration[5.2]
  def change
    Health::Tracing::Contact.with_deleted.each do |contact|
      result = contact.results.build
      result.update(
        test_result: contact.test_result,
        isolated: contact.isolated,
        isolation_location: contact.isolation_location,
        quarantine: contact.quarantine,
        quarantine_location: contact.quarantine_location,
        deleted_at: contact.deleted_at,
      )
    end
  end
end
