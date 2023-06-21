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
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user)).distinct.
      pluck(:CoCCode, :hud_coc_code).flatten.uniq.map(&:presence).compact
    # Include CoCs where the user has access to a project that only operates in that CoC
    inherited_coc_codes = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, include_cocs: false)).
      distinct.
      pluck(p_t[:id], cl(pc_t[:hud_coc_code], pc_t[:CoCCode])).
      group_by(&:shift).
      transform_values(&:flatten).
      select { |_, codes| codes.count == 1 }.
      values.
      uniq.flatten
    possible_cocs = inherited_coc_codes + user.coc_codes
    coc_codes &= possible_cocs if possible_cocs.present?
    active.where(coc_code: coc_codes)
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
