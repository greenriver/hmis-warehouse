###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::Organization < Hmis::Hud::Base
  self.table_name = :Organization
  self.sequence_name = "public.\"#{table_name}_id_seq\""
  has_paper_trail
  include ::HmisStructure::Organization
  include ::Hmis::Hud::Concerns::HasCustomDataElements
  include ::Hmis::Hud::Concerns::Shared

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  has_many :projects, **hmis_relation(:OrganizationID, 'Project'), dependent: :destroy
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :organizations

  has_many :group_viewable_entity_projects
  has_many :group_viewable_entities, through: :group_viewable_entity_projects, source: :group_viewable_entity

  validates_with Hmis::Hud::Validators::OrganizationValidator

  # hide previous declaration of :viewable_by, we'll use this one
  # Any organizations the user has been assigned, limited to the data source the HMIS is connected to
  replace_scope :viewable_by, ->(user) do
    ids = user.viewable_organizations.pluck(:id)
    ids += user.viewable_data_sources.joins(:organizations).pluck(o_t[:id])
    # If a user can see a project within the organization, they can see the organization
    ids += user.viewable_projects.joins(:organization).pluck(o_t[:id])
    where(id: ids, data_source_id: user.hmis_data_source_id)
  end

  scope :matching_search_term, ->(search_term) do
    return none unless search_term.present?

    search_term.strip!
    query = "%#{search_term.split(/\W+/).join('%')}%"

    where(
      o_t[:OrganizationName].matches(query).
        or(o_t[:id].eq(possibly_pk?(search_term) ? search_term : '')).
        or(o_t[:organization_id].eq(search_term)),
    )
  end

  SORT_OPTIONS = [:name].freeze

  def self.sort_by_option(option)
    raise NotImplementedError unless SORT_OPTIONS.include?(option)

    case option
    when :name
      order(:OrganizationName, id: :desc)
    else
      raise NotImplementedError
    end
  end

  def self.apply_filters(input)
    Hmis::Filter::OrganizationFilter.new(input).filter_scope(self)
  end

  def to_pick_list_option
    {
      code: id,
      label: organization_name,
    }
  end

  def name
    organization_name
  end
end
