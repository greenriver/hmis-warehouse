###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::User < ::User
  has_many :user_hmis_data_sources_roles, dependent: :destroy, inverse_of: :user # join table with user_id, data_source_id, role_id
  has_many :roles, thorugh: :hmis_data_sources, source: :role
  has_many :hmis_data_sources, through: :user_hmis_data_sources_roles, source: :data_source
  attr_accessor :hmis_data_source_id # stores the data_source_id of the currently logged in HMIS

  def skip_session_limitable?
    true
  end
end
