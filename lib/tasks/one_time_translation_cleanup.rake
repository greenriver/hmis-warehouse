# frozen_string_literal: true

desc 'One time cleanup of cohort translation descriptions to remove previous defaults'
# rails cleanup_default_cohort_translations
task cleanup_default_cohort_translations: [:environment] do
  # Process cohort column defaults
  columns = GrdaWarehouse::Cohort.available_columns

  columns.each do |column|
    next unless column.attributes.include?(:description_translation_key)

    key = column.description_translation_key
    translation = Translation.where(key: key).first_or_create
    # If it already matches the expected description, do nothing
    next if translation.text == column.description
    # If this has been translated manually, don't re-translate
    next if translation.text.present? && !translation.text.include?('Description')

    # Force using the default description
    translation.update(text: column.description)
    Translation.invalidate_translation_cache(key) # force re-calculation
  end
  # Force re-translation
  Translation.translate(Translation.first.key)
end
