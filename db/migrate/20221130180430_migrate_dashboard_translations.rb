class MigrateDashboardTranslations < ActiveRecord::Migration[6.1]
  def translation_mappings
    [
      {
        old: 'Search',
        new: [
          'Clients in Search',
          'Clients Entering Search',
          'entered Search during the reporting period',
          'Clients Exiting Search',
          'exited Search during the reporting period',
          'Average Time in Search for the Reporting Period',
          'Time in Search with Exits to Housing',
          'Time in Search with an Exit not to Housing',
          'Time in Search with an Exit to Any Destination']
      },
      {
        old: 'search',
        new: [
          'were in search',
          'was in search',
          'Percentage of clients exiting search to housing out of those who exited search',
          'Percentage of clients enrolled in housing out of those enrolled in either search or housing']
      },
      {
        old: 'Housing',
        new: [
          'Clients in Housing',
          'Clients Entering Housing',
          'entered Housing during the reporting period',
          'Clients Exited Housing',
          'exited Housing during the reporting period',
          'Time in Search with Exits to Housing',
          'Time in Search with an Exit not to Housing',
          'Time in Housing with an Exit to Any Destination',
          'Average Time in Housing for the Reporting Period']
      },
      {
        old: 'housing',
        new: [
          'were enrolled in housing',
          'was enrolled in housing',
          'Percentage of clients exiting search to housing out of those who exited search',
          'Percentage of clients enrolled in housing out of those enrolled in either search or housing',
          'Percentage of clients exiting housing to a permanent destination out of those who exited housing']
      }
    ]
  end

  # Generate translations for new keys based on old ones (if any)
  def up
    updated = []
    translation_mappings.each do |m|
      old_key = m[:old]
      new_keys = m[:new]
      key = TranslationKey.find_by(key: old_key)

      # find all translations for 'Search'
      key.translations.where.not(text: nil).each do |t|
        # Iterate through all new translations that use 'Search'
        new_keys.each do |k|
          new_key = TranslationKey.where(key: k).first_or_create
          # Create a translation for the new key ('Clients in Search')
          translation = TranslationText.find_or_create_by(
            locale: t.locale,
            translation_key_id: new_key.id
          )
          translation.text ||= k
          # Replace 'Clients in Search' => 'Clients in <text>'
          translation.text = translation.text.gsub(/\b#{old_key}\b/, t.text)
          translation.save!
          updated << translation.text
        end
      end
    end
    pp updated
  end

  # Delete all translations for the new keys
  def down
    translation_mappings.each do |m|
      m[:new].each do |k|
        key = TranslationKey.find_by(key: k)
        key.translations.where.not(text: nil).destroy_all
      end
    end
  end
end
