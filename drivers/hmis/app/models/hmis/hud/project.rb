###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Project < Hmis::Hud::Base
  include ArelHelper
  include ::HmisStructure::Project
  include ::Hmis::Hud::Concerns::Shared
  include ProjectSearch
  self.table_name = :Project
  self.sequence_name = "public.\"#{table_name}_id_seq\""

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :organization, **hmis_relation(:OrganizationID, 'Organization')
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :projects

  has_many :project_cocs, **hmis_relation(:ProjectID, 'ProjectCoc'), inverse_of: :project
  has_many :inventories, **hmis_relation(:ProjectID, 'Inventory'), inverse_of: :project
  has_many :funders, **hmis_relation(:ProjectID, 'Funder'), inverse_of: :project

  validates_with Hmis::Hud::Validators::ProjectValidator

  # hide previous declaration of :viewable_by, we'll use this one
  # Any projects the user has been assigned, limited to the data source the HMIS is connected to
  replace_scope :viewable_by, ->(user) do
    ids = user.viewable_projects.pluck(:id)
    ids += user.viewable_organizations.joins(:projects).pluck(p_t[:id])
    ids += user.viewable_data_sources.joins(:projects).pluck(p_t[:id])
    ids += user.viewable_project_access_groups.joins(:projects).pluck(p_t[:id])

    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  # hide previous declaration of :editable_by, we'll use this one
  replace_scope :editable_by, ->(user) do
    ids = user.editable_projects.pluck(:id)
    ids += user.organizations.joins(:projects).pluck(p_t[:id])
    ids += user.data_sources.joins(:projects).pluck(p_t[:id])
    ids += user.project_access_groups.joins(:projects).pluck(p_t[:id])

    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  # Always use ProjectType, we shouldn't need overrides since we can change the source data
  scope :with_project_type, ->(project_types) do
    where(ProjectType: project_types)
  end

  SORT_OPTIONS = [:organization_and_name, :name].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :name
      order(:ProjectName)
    when :organization_and_name
      joins(:organization).order(o_t[:OrganizationName], p_t[:ProjectName])
    else
      raise NotImplementedError
    end
  end

  def self.project_search(input:, user: nil)
    scope = Hmis::Hud::Project.where(id: viewable_by(user).select(:id))
    scope = text_searcher(input.text_search, scope) if input.text_search.present?
    Hmis::Hud::Project.where(id: scope.select(:id))
  end

  def self.generate_project_id
    generate_uuid
  end

  def active
    return true unless operating_end_date.present?

    operating_end_date >= Date.today
  end
end
