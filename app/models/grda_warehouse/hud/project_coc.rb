module GrdaWarehouse::Hud
  class ProjectCoc < Base
    include HudSharedScopes
    self.table_name = 'ProjectCoC'
    self.hud_key = 'ProjectCoCID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "ProjectCoCID",
        "ProjectID",
        "CoCCode",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :project_cocs
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :project_coc
    belongs_to :export, **hud_belongs(Export), inverse_of: :project_cocs
    has_many :sites, class_name: 'GrdaWarehouse::Hud::Site', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    has_many :inventories, class_name: 'GrdaWarehouse::Hud::Inventory', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc

    scope :in_coc, -> (coc_code:) do
      # hud_coc_code overrides CoCCode
      where(
        arel_table[:CoCCode].eq(coc_code).and(arel_table[:hud_coc_code].eq(nil)).
        or(arel_table[:hud_coc_code].eq(coc_code))
      )
    end
  end
end