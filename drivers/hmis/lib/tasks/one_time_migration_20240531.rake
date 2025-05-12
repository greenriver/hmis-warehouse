# frozen_string_literal: true

desc 'One time data migration to publish all form definitions'
# rails driver:hmis:migrate_definitions_20240531
task migrate_definitions_20240531: [:environment] do
  Hmis::Form::Definition.latest_versions.where(status: :draft).update_all(status: :published)
end
