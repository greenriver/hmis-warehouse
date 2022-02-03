###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Nickname < ApplicationRecord
  belongs_to :nicknames, optional: true
  scope :for, -> (name) { where(nickname_id: where(name: name.downcase)) }

  def self.populate!
    Rails.logger.info 'Populating the nicknames table'
    Nickname.delete_all
    names_uri = URI('https://raw.githubusercontent.com/carltonnorthern/nickname-and-diminutive-names-lookup/master/names.csv')
    Rails.logger.info "Fetching the nicknames from #{names_uri} ..."
    file = Net::HTTP.get names_uri
    Rails.logger.info 'fetched'
    # Build nicknames connected with nickname_id
    file.split("\n").each do |line|
      names = line.chomp.split(',')
      nickname_id = nil
      names.each do |n|
        if nickname_id.blank?
          nick = Nickname.create(name: n)
          nickname_id = nick.id
          nick.update_attribute(:nickname_id, nick.id)
        else
          Nickname.create(name: n, nickname_id: nickname_id)
        end
      end
    end
    Rails.logger.info "#{Nickname.count} Nicknames added"
  end
end
