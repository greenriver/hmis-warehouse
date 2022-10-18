###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::User < Hmis::Hud::Base
  include ::HmisStructure::User
  include ::Hmis::Hud::Shared
  self.table_name = :User
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  has_many :affiliations, **hmis_relation(:UserID, 'Affiliation')
  has_many :clients, **hmis_relation(:PersonalID, 'Client')
  has_many :enrollments, **hmis_relation(:UserID, 'Enrollment')
  has_many :organizations, **hmis_relation(:UserID, 'Organization')
  has_many :projects, **hmis_relation(:UserID, 'Project')
  has_many :services, **hmis_relation(:UserID, 'Service')
  has_many :assessments, **hmis_relation(:UserID, 'Assessment')
  has_many :events, **hmis_relation(:UserID, 'Event')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  def self.from_user(user)
    Hmis::Hud::User.where(user_email: user.email, data_source_id: user.hmis_data_source_id).first_or_create do |u|
      u.user_id = user.id
      u.user_first_name = user.first_name
      u.user_last_name = user.last_name
      u.data_source_id = user.hmis_data_source_id
    end
  end
end
