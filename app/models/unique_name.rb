###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UniqueName < ApplicationRecord
  def self.update!
    Rails.logger.info 'Updating the unique names table'

    # Build double metaphone representations for all names in the database
    existing_names = UniqueName.pluck(:name)
    all_names = GrdaWarehouse::Hud::Client.source.distinct.pluck('FirstName').map { |n| n.to_s.downcase } +
      GrdaWarehouse::Hud::Client.source.distinct.pluck('LastName').map { |n| n.to_s.downcase }
    new_names = all_names - existing_names
    name_objects = []
    new_names.uniq.each do |name|
      double_metaphone = Text::Metaphone.double_metaphone(name)
      name_objects << UniqueName.new(name: name, double_metaphone: double_metaphone)
    end
    UniqueName.import name_objects
  end
end
