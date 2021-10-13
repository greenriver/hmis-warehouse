###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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

  scope :viewable_by, ->(user) do
    coc_codes = GrdaWarehouse::Hud::ProjectCoc.joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user)).distinct.
      pluck(:CoCCode, :hud_coc_code).flatten.uniq.map(&:presence).compact
    coc_codes &= user.coc_codes if user.coc_codes.present?
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
