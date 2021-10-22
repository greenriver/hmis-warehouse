Rails.logger.debug "Running initializer in #{__FILE__}"

# db access is cached <-> only first lookup hits the db
def database_exists?
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished
  false
else
  true
end

if database_exists? && ActiveRecord::Base.connection.table_exists?('translation_keys')
  require 'gettext_i18n_rails'
  require 'fast_gettext'
  require 'gettext'
  require "fast_gettext/translation_repository/db"
  FastGettext::TranslationRepository::Db.require_models #load and include default models

  FastGettext.add_text_domain(
    'hmis_warehouse',
    :path => 'locale',
    :type => :db,
    :model => TranslationKey,
    :ignore_fuzzy => true,
    # :report_warning => false
  )
  FastGettext.default_available_locales = [:en]
  FastGettext.default_text_domain = 'hmis_warehouse'
else
  FastGettext.add_text_domain('hmis_warehouse', :path => 'locale')
  FastGettext.default_text_domain = 'hmis_warehouse'
end
