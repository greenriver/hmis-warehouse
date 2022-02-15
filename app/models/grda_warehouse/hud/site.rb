###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Site < Base
    include HudSharedScopes
    include ::HMIS::Structure::Base
    include RailsDrivers::Extensions
    acts_as_paranoid column: :DateDeleted

    attr_accessor :source_id

    self.table_name = 'Site'
    self.sequence_name = "public.\"#{table_name}_id_seq\""
    self.hud_key = 'GeographyID'

    belongs_to :project_coc, class_name: 'GrdaWarehouse::Hud::ProjectCoc', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :geographies, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :geographies, optional: true
    has_one :project, through: :project_coc, source: :project
    belongs_to :data_source

    scope :viewable_by, ->(user) do
      if GrdaWarehouse::DataSource.can_see_all_data_sources?(user)
        current_scope
      elsif user.coc_codes.none?
        none
      else
        joins(:project_coc).merge(GrdaWarehouse::Hud::ProjectCoc.viewable_by(user))
      end
    end

    def self.hud_csv_headers(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      [
        :GeographyID,
        :ProjectID,
        :CoCCode,
        :PrincipalSite,
        :Geocode,
        :Address,
        :City,
        :State,
        :ZIP,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    end

    def name
      "#{self.Address} #{self.City}"
    end

    # when we export, we always need to replace GeographyID with the value of id
    # and ProjectID with the id of the related project
    def self.to_csv(scope:)
      attributes = hud_csv_headers
      headers = attributes.clone
      attributes[attributes.index('GeographyID')] = 'id'
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

    def self.related_item_keys
      [:ProjectID]
    end
  end
end
