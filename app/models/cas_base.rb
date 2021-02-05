###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CasBase < ActiveRecord::Base
  cas_db = Rails.env == "test" ? :test : "#{Rails.env}_cas".parameterize.underscore.to_sym
  establish_connection cas_db
  self.abstract_class = true

  def self.db_exists?
    self.connection_pool.with_connection(&:active?) rescue false
  end
end
