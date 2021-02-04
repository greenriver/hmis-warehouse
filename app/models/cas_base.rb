###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CasBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_cas".parameterize.underscore.to_sym
  self.abstract_class = true

  def self.db_exists?
    connection_pool.with_connection(&:active?)
  rescue StandardError
    false
  end
end
