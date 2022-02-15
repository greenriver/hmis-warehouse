###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UniqueName < ApplicationRecord
  def self.update!
    Rails.logger.info 'Updating the unique names table'

    # Build double metaphone representations for all names in the database
    existing_names = UniqueName.pluck(:name)
    all_names = GrdaWarehouse::Hud::Client.source.distinct.where.not(FirstName: [nil, '']).pluck('FirstName').map(&:downcase) +
      GrdaWarehouse::Hud::Client.source.distinct.where.not(LastName: [nil, '']).pluck('LastName').map(&:downcase)
    new_names = all_names - existing_names
    name_objects = []
    new_names.uniq.each do |name|
      next unless name.present?

      double_metaphone = Text::Metaphone.double_metaphone(name)
      name_objects << UniqueName.new(name: name, double_metaphone: double_metaphone)
    end
    UniqueName.import name_objects
  end
end
