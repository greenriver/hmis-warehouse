###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HMIS uses similar but separate permissions system from the warehouse
# @see docs/features/hmis/hmis-permissions.md

class Hmis::AccessControl < ApplicationRecord
  include AccessControlFiltering

  acts_as_paranoid
  has_paper_trail

  belongs_to :access_group, class_name: '::Hmis::AccessGroup'
  belongs_to :role, class_name: 'Hmis::Role'
  belongs_to :user_group, class_name: '::Hmis::UserGroup', required: false, inverse_of: :access_controls
  has_many :users, through: :user_group

  def entity_name
    "#{role&.name || 'missing role'} x #{access_group&.name || 'missing collection'} x #{user_group&.name || 'missing user group'}"
  end

  def self.describe_changes(version, changes, excluded_fields = [])
    case version.event
    when 'create'
      ['Created access control']
    when 'destroy'
      ['Deleted access control']
    else
      filtered = (changes || {}).reject { |field, _| excluded_fields.include?(field.to_s) }
      filtered.map do |field, (from_id, to_id)|
        from_name = resolve_fk_name(field, from_id)
        to_name = resolve_fk_name(field, to_id)
        "Changed #{field.humanize.titleize}: from #{from_name} to #{to_name}"
      end.presence || ['Updated access control']
    end
  end

  def self.resolve_fk_name(field, id)
    return 'none' if id.nil?

    klass = case field.to_s
    when 'role_id' then Hmis::Role
    when 'user_group_id' then Hmis::UserGroup
    when 'access_group_id' then Hmis::AccessGroup
    end
    klass ? (klass.with_deleted.find_by(id: id)&.name || "ID #{id}") : id.to_s
  end
  private_class_method :resolve_fk_name

  scope :ordered, -> do
    joins(:user_group, :role, :access_group).
      order(
        Hmis::UserGroup.arel_table[:name].lower.asc,
        Hmis::Role.arel_table[:name].lower.asc,
        Hmis::AccessGroup.arel_table[:name].lower.asc,
      )
  end

  filterable_by(
    collection_association: :access_group,
    entity_class_names: {
      data_source_id: 'GrdaWarehouse::DataSource',
      organization_id: 'Hmis::Hud::Organization',
      project_id: 'Hmis::Hud::Project',
    },
  )
end
