module GrdaWarehouse::Hud
  class ProjectCoc < Base
    include HudSharedScopes
    self.table_name = 'ProjectCoC'
    self.hud_key = :ProjectCoCID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :ProjectCoCID,
        :ProjectID,
        :CoCCode,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :project_cocs
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :project_coc
    belongs_to :export, **hud_belongs(Export), inverse_of: :project_cocs
    has_many :geographies, class_name: 'GrdaWarehouse::Hud::Geography', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    has_many :inventories, class_name: 'GrdaWarehouse::Hud::Inventory', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc

    scope :in_coc, -> (coc_code:) do
      # hud_coc_code overrides CoCCode
      coc_code = Array(coc_code)
      pc_t = arel_table
      where(
        pc_t[:CoCCode].in(coc_code).and(pc_t[:hud_coc_code].eq(nil).or(pc_t[:hud_coc_code].eq(''))).
        or(pc_t[:hud_coc_code].in(coc_code))
      )
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

  end
end
