###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::Lookups::CocCode < GrdaWarehouseBase
  has_many :project_cocs, class_name: '::GrdaWarehouse::Hud::ProjectCoc', foreign_key: :CoCCode, primary_key: :coc_code, inverse_of: :lookup_coc
  has_many :projects, through: :project_cocs
  has_many :data_sources, through: :project_cocs

  scope :active, -> do
    where(active: true)
  end

  ##
  # Returns all active CoC codes that the given user can view based on permissions.
  #
  # NOTE: This scope is primarily used for generating filters and should **not** be used for calculating
  # client visibility.
  #
  # @param user [User] The user whose permissions will be checked.
  # @param permission [Symbol] The permission used to determine if the user can view the CoC codes.
  #   Defaults to `:can_view_projects`.
  # @return [ActiveRecord::Relation<GrdaWarehouse::Lookups::CocCode>] an ActiveRecord::Relation of CoC codes
  #   that the user is allowed to view.
  #
  scope :viewable_by, ->(user, permission: :can_view_projects) do
    # Fetch all CoC codes that are indirectly accessible to the user via projects they have permission to view.
    coc_codes_inherited_from_projects = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission)).distinct.
      pluck(:CoCCode)
    # If the user can't see any CoC Codes from the above query, it's probably that they don't have any
    # access to view projects. We'll fix that with different permissions in the future, for now return all
    active_coc_codes = active.distinct.pluck(:coc_code)
    # Intersect the active CoC codes with the specific CoC codes explicitly assigned to the user.
    # This ensures the user can only see codes they have explicit access to, in addition to inherited ones.
    visible_coc_codes = []
    visible_coc_codes = active_coc_codes & user.coc_codes if user.coc_codes.present?
    visible_coc_codes += coc_codes_inherited_from_projects

    active.where(coc_code: visible_coc_codes.uniq)
  end

  def self.options_for_select(user:, permission: :can_view_projects)
    viewable_by(user, permission: permission).
      distinct.
      order(:coc_code).
      map(&:as_select_option)
  end

  def as_select_option
    [
      name,
      coc_code,
    ]
  end

  def name
    "#{preferred_name || official_name} (#{coc_code})"
  end
end
