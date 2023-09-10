###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Translation < ApplicationRecord
  include NotifierConfig

  def self.translate(text)
    Rails.cache.fetch("translations/#{text}", expires_in: 15.minutes) do
      translations = all.pluck(:key, :text).to_h
      translations.each do |k, v|
        Rails.cache.write("translations/#{k}", (v.presence || k), expires_in: 15.minutes)
      end
      translated = translations[text]
      if ! translations.key?(text)
        msg = "Unknown Translation key #{text}"
        # Fail painfully if this is development so we see the error of our ways
        raise msg if Rails.env.development?

        # Notify if this isn't development so we can track it down loater
        setup_notifier('Translation')
        @notifier.ping(
          msg,
          {
            exception: StandardError.new(msg),
          },
        )
      end

      translated.presence || text
    end
  end

  def self.invalidate_translations
    Rails.cache.delete_matched('translations/*')
  end

  def self.invalidate_translation(key)
    Rails.cache.delete("translations/#{key}")
  end
end
