module GrdaWarehouse::Hud
  class Site < Base
    self.table_name = 'Site'
    self.hud_key = 'SiteID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "SiteID",
        "ProjectID",
        "CoCCode",
        "PrincipalSite",
        "Geocode",
        "Address",
        "City",
        "State",
        "ZIP",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :project_coc, class_name: 'GrdaWarehouse::Hud::ProjectCoc', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :sites
    belongs_to :export, **hud_belongs(Export), inverse_of: :sites
    has_one :project, through: :project_coc, source: :project

    def name
      "#{self.Address} #{self.City}"
    end

    # when we export, we always need to replace SiteID with the value of id
    # and ProjectID with the id of the related project
    def self.to_csv(scope:)
      attributes = self.hud_csv_headers
      headers = attributes.clone
      attributes[attributes.index('SiteID')] = 'id'
      attributes[attributes.index('ProjectID')] = 'project.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            # we need to grab the appropriate id from the related project
            if attr.include?('.')
              obj, meth = attr.split('.')
              i.send(obj).send(meth)
            else
              i.send(attr)
            end 
          end
        end
      end
    end
  end
end