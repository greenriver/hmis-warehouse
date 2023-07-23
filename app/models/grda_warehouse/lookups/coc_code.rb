###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
  scope :viewable_by, ->(user) do
    # any code the client could possibly have access to, and the project associated
    visible_coc_codes = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user)).distinct.
      pluck(p_t[:id], GrdaWarehouse::Hud::ProjectCoc.coc_code_coalesce)
    # Ideally we'll only show the CoC codes that the user obtained directly, or
    # where a project only operates in one coc
    coc_codes = visible_coc_codes.
      group_by(&:shift).
      transform_values(&:flatten).
      select { |_, codes| codes.count == 1 }.
      values.
      uniq.flatten
    # Sometimes a person may only have access to a few projects, and all of those projects
    # operates in multiple CoCs.  This would leave us with no CoC Codes, which will break
    # some reports.  In that case, just return the unique CoC Codes they have
    coc_codes = visible_coc_codes.map(&:last).compact.uniq if coc_codes.blank? && user.coc_codes.blank?

    possible_cocs = coc_codes + user.coc_codes
    active.where(coc_code: possible_cocs)
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
