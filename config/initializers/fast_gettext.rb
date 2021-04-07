Rails.logger.debug "Running initializer in #{__FILE__}"

def enable_transation_db?
  return false if ENV['DISABLE_FAST_GETTEXT_DB']
  # db access is cached <-> only first lookup hits the db
  ActiveRecord::Base.connection
rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad
  false
else
  true
end

FastGettext.default_available_locales = ['en']
FastGettext.default_text_domain = 'hmis_warehouse'
if enable_transation_db? && ActiveRecord::Base.connection.table_exists?('translation_keys')
  require 'gettext_i18n_rails'
  require 'fast_gettext'
  require 'gettext'
  require "fast_gettext/translation_repository/db"
  FastGettext::TranslationRepository::Db.require_models #load and include default models

  FastGettext.add_text_domain(
    FastGettext.default_text_domain,
    path: 'locale',
    type: :db,
    model: TranslationKey,
    ignore_fuzzy: true,
  )
else
  FastGettext.add_text_domain(FastGettext.default_text_domain, path: 'config/locales', type: :yaml)
end
