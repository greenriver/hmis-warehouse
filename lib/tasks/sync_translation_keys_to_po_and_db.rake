desc "sync translation keys to po files then sync po files with db"
task :sync_translation_keys_to_po_and_db => :environment do
  Rake::Task["gettext:find"].invoke
  Rake::Task[:sync_po_to_db].invoke
end
