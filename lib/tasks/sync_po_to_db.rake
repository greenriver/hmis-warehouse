desc "synchronise po files with db, creating keys and translations that do not exist"
task :sync_po_to_db => :environment do
  folder = ENV['FOLDER']||'locale'

  gem 'grosser-pomo', '>=0.5.1'
  require 'pomo'
  require 'pathname'
  
  #find all files we want to read
  po_files = []
  Pathname.new(folder).find do |p|
    next unless p.to_s =~ /\.po$/
    po_files << p
  end

  #insert all their translation into the db
  po_files.each do |p|
    #read translations from po-files
    locale = p.dirname.basename.to_s
    next unless locale =~ /^[a-z]{2}([-_][a-z]{2})?$/i
    puts "Reading #{p.to_s}"
    translations = Pomo::PoFile.parse(p.read)

    #add all non-fuzzy translations to the database
    translations.reject(&:fuzzy?).each do |t|
      next if t.msgid.blank? #atm do not insert metadata

      key = TranslationKey.find_or_create_by_key(t.msgid)
      #do not overwrite existing translations
      next if key.translations.detect{|text| text.locale == locale}

      #store translations
      # make sure we store nil (NULL) values if msgstr is blank
      # so that the _() method will see that the string is not translated
      t.msgstr.blank? ? t.msgstr = nil : t.msgstr = t.msgstr
      puts "Creating text #{locale}:#{t.msgstr}"
      key.translations.create!(:locale=>locale, :text=>t.msgstr)
    end
  end
end
