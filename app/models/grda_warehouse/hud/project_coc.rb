###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class ProjectCoc < Base
    include HudSharedScopes
    include ::HMIS::Structure::ProjectCoc
    include ArelHelper

    self.table_name = 'ProjectCoC'
    self.hud_key = :ProjectCoCID
    acts_as_paranoid column: :DateDeleted

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :project_cocs
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :project_cocs, optional: true
    has_many :geographies, class_name: 'GrdaWarehouse::Hud::Geography', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    has_many :inventories, class_name: 'GrdaWarehouse::Hud::Inventory', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    belongs_to :data_source

    scope :in_coc, -> (coc_code:) do
      # hud_coc_code overrides CoCCode
      coc_code = Array(coc_code)
      where(
        pc_t[:CoCCode].in(coc_code).and(pc_t[:hud_coc_code].eq(nil).or(pc_t[:hud_coc_code].eq(''))).
        or(pc_t[:hud_coc_code].in(coc_code))
      )
    end

    scope :with_coc, -> do
      where.not(CoCCode: nil).or(where.not(hud_coc_code: nil))
    end

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.coc_codes.none?
        none
      else
        in_coc( coc_code: user.coc_codes )
      end
    end

    def effective_coc_code
      return hud_coc_code if hud_coc_code.present?

      self.CoCCode
    end

    def self.related_item_keys
      [:ProjectID]
    end

    def self.available_coc_codes
      distinct.order(:CoCCode).pluck(:CoCCode)
    end

    def self.options_for_select user:
      # don't cache this, it's a class method
      viewable_by(user).
        distinct.
        order(CoCCode: :asc).
        pluck(:CoCCode).
        map do |coc_code|
          [
            coc_code,
            coc_code,
          ]
        end
    end
  end
end
