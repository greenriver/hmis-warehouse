###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::Lookups::CocCode < GrdaWarehouseBase
  belongs_to :project_coc, class_name: '::GrdaWarehouse::Hud::ProjectCoc', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :lookup_coc
  belongs_to :enrollment_coc, class_name: '::GrdaWarehouse::Hud::EnrollmentCoc', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :lookup_coc

  scope :active, -> do
    where(active: true)
  end

  scope :viewable_by, -> (user) do
    active.joins(project_coc: :project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(user))
  end

  def self.as_select_options(user)
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