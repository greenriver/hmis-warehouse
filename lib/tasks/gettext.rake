namespace :gettext do
  def files_to_translate
    Dir.glob("{app}/**/*.{rb,haml}")# + Dir.glob("{app}/controllers/**/*.{rb}")# + Dir.glob("{app}/models/**/*.{rb}")
  end

  desc "synchronise po files with db, creating keys and translations that do not exist"
  task :sync_po_to_db => :environment do
    folder = ENV['FOLDER']||'locale'

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

        key = TranslationKey.where(key: t.msgid).first_or_create
        #do not overwrite existing translations
        next if key.translations.detect{|text| text.locale == locale}

        #store translations
        # make sure we store nil (NULL) values if msgstr is blank
        # so that the _() method will see that the string is not translated
        t.msgstr.blank? ? t.msgstr = nil : t.msgstr = t.msgstr
        puts "Creating text #{locale}:#{t.msgid}"
        key.translations.create!(locale: locale, text: t.msgstr)
      end
    end
  end

  desc "sync translation keys to po files then sync po files with db"
  task :sync_to_po_and_db => :environment do
    Rake::Task["gettext:find"].invoke
    Rake::Task['gettext:sync_po_to_db'].invoke
  end

end
