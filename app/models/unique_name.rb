class UniqueName < ActiveRecord::Base

  def self.update!
    Rails.logger.info 'Updating the unique names table'

    # Build double metaphone representations for all names in the database
    names = GrdaWarehouse::Hud::Client.source.select('FirstName').distinct.pluck('FirstName')&.map(&:downcase) + GrdaWarehouse::Hud::Client.source.select('LastName').distinct.pluck('LastName')&.map(&:downcase)
    names.uniq.each do |name|
      double_metaphone = Text::Metaphone.double_metaphone(name)
      un = UniqueName.where(name: name).first_or_create
      un.double_metaphone = double_metaphone
      un.save
    end
  end
end