module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    self.table_name = 'Affiliation'
    self.hud_key = :AffiliationID
    acts_as_paranoid column: :DateDeleted
    has_many :users

    def self.hud_csv_headers(version: nil)
      [
        :AffiliationID,
        :ProjectID,
        :ResProjectID,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :affiliations
    belongs_to :residential_project, class_name: GrdaWarehouse::Hud::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ResProjectID, :data_source_id], inverse_of: :affiliations
    belongs_to :export, **hud_belongs(Export), inverse_of: :affiliations
  end
end
