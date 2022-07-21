###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Organization < Hmis::Hud::Base
  include ::HmisStructure::Organization
  include ::Hmis::Hud::Shared
  self.table_name = :Organization
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  has_many :projects, **hmis_relation(:OrganizationID, 'Project')

  # Any organizations the user has been assigned, limited to the data source the HMIS is connected to
  scope :viewable_by, ->(user) do
    viewable_ids = GrdaWarehouse::Hud::Organization.viewable_by(user).pluck(:id)
    where(id: viewable_ids, data_source_id: user.hmis_data_source_id)
  end

  SORT_OPTIONS = [:name].freeze

  def self.sort_by_option(option, direction)
    raise NotImplementedError unless SORT_OPTIONS.include?(option) && [:asc, :desc].include?(direction)

    case option
    when :name
      order(OrganizationName: direction)
    else
      raise NotImplementedError
    end
  end
end
