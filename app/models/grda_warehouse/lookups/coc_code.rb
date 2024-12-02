###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::Lookups::CocCode < GrdaWarehouseBase
  belongs_to :project_coc, class_name: '::GrdaWarehouse::Hud::ProjectCoc', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :lookup_coc, optional: true
  belongs_to :overridden_project_coc, class_name: '::GrdaWarehouse::Hud::ProjectCoc', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :overridden_lookup_coc, optional: true
  belongs_to :enrollment_coc, class_name: '::GrdaWarehouse::Hud::EnrollmentCoc', primary_key: :hud_coc_code, foreign_key: :coc_code, inverse_of: :lookup_coc, optional: true

  scope :active, -> do
    where(active: true)
  end

  # NOTE: this is only used for generating filters, it is not to be used when calculating
  # client visibility
  scope :viewable_by, ->(user, permission: :can_view_projects) do
    # any code the user could possibly have access to, and the project associated
    visible_coc_codes = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: permission)).distinct.
      pluck(:CoCCode)
    # If the user can't see any CoC Codes from the above query, it's probably that they don't have any
    # access to view projects. We'll fix that with different permissions in the future, for now return all
    visible_coc_codes = active.distinct.pluck(:coc_code) if visible_coc_codes.blank?
    # Intersected with the user's since the visible_coc_codes returned all CoC codes at the projects
    visible_coc_codes &= user.coc_codes if user.coc_codes.present?

    active.where(coc_code: visible_coc_codes)
  end

  def self.options_for_select(user:)
    viewable_by(user).
      distinct.
      order(:coc_code).
      map(&:as_select_option)
  end

  def as_select_option
    [
      "#{preferred_name || official_name} (#{coc_code})",
      coc_code,
    ]
  end
end
