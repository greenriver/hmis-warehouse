module GrdaWarehouse::Hud
  class Affiliation < Base
    include HudSharedScopes
    self.table_name = 'Affiliation'
    self.hud_key = 'AffiliationID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "AffiliationID",
        "ProjectID",
        "ResProjectID",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ].freeze
    end

    belongs_to :project, **hud_belongs(Project), inverse_of: :affiliations
    belongs_to :export, **hud_belongs(Export), inverse_of: :affiliations
  end
end