###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class UniqueName < ApplicationRecord

  def self.update!
    Rails.logger.info 'Updating the unique names table'

    # Build double metaphone representations for all names in the database
    names = GrdaWarehouse::Hud::Client.source.select('FirstName').distinct.pluck('FirstName')&.map{ |n| n&.downcase || ''} + GrdaWarehouse::Hud::Client.source.select('LastName').distinct.pluck('LastName')&.map{ |n| n&.downcase || ''}
    names.uniq.each do |name|
      double_metaphone = Text::Metaphone.double_metaphone(name)
      un = UniqueName.where(name: name).first_or_create
      un.double_metaphone = double_metaphone
      un.save
    end
  end
end