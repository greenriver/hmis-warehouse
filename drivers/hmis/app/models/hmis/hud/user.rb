###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::User < Hmis::Hud::Base
  include ::HmisStructure::User
  include ::Hmis::Hud::Concerns::Shared
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
  has_many :custom_data_elements, **hmis_relation(:UserID, 'CustomDataElement')
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  replace_scope :viewable_by, ->(user) do
    data_source_id = user.hmis_data_source_id
    raise 'user missing data source id' unless data_source_id

    return none unless user.permissions?(:can_impersonate_users)

    # FIXME:
    # perhaps there's some additional restriction needed here to prevent users
    # from escalating privileges or jumping data sources within the app?
    skipped_ids = []
    skipped_ids << system_user(data_source_id: data_source_id).id
    where(data_source_id: data_source_id).where.not(id: skipped_ids)
  end

  # Find or create the Hmis::Hud::User corresponding to the provided application user (Hmis::User)
  def self.from_user(user)
    Hmis::Hud::User.where(user_email: user.email.downcase, data_source_id: user.hmis_data_source_id).first_or_create do |u|
      u.user_id = Hmis::Hud::Base.generate_uuid
      u.user_first_name = user.first_name
      u.user_last_name = user.last_name
      phone = user.phone&.gsub(/\D/, '')
      u.user_phone = phone if phone && phone.size < 11 # column has 10 char limit
    end
  end

  # @param data_source_id [Integer]
  def self.system_user(data_source_id:)
    system_user = Hmis::User.find(User.system_user.id)
    system_user.hmis_data_source_id = data_source_id
    Hmis::Hud::User.from_user(system_user)
  end
end
