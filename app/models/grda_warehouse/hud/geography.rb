###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Geography < Base
    include HudSharedScopes
    # Since this Geography is no longer included in the HMIS spec, we're not creating
    # the struture file
    # include ::HMIS::Structure::Geography
    include ::HMIS::Structure::Base
    include RailsDrivers::Extensions

    self.table_name = 'Geography'
    self.sequence_name = "public.\"#{table_name}_id_seq\""
    self.hud_key = :GeographyID
    acts_as_paranoid column: :DateDeleted

    belongs_to :project_coc, class_name: 'GrdaWarehouse::Hud::ProjectCoc', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :geographies, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :geographies, optional: true
    has_one :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :geographies
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

    def self.hmis_structure(version: nil)
      case version
      when '5.1', '6.11', '6.12'
        {
          GeographyID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          CoCCode: {
            type: :string,
            limit: 6,
            null: false,
          },
          InformationDate: {
            type: :date,
            null: false,
          },
          Geocode: {
            type: :string,
            limit: 6,
            null: false,
          },
          GeographyType: {
            type: :integer,
            null: false,
          },
          Address1: {
            type: :string,
            limit: 100,
          },
          Address2: {
            type: :string,
            limit: 100,
          },
          City: {
            type: :string,
            limit: 50,
          },
          State: {
            type: :string,
            limit: 2,
          },
          ZIP: {
            type: :string,
            limit: 5,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      end
    end

    def self.hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:GeographyID, :ProjectID] => nil,
        [:ExportID] => nil,
      }
    end

    # For posterity
    # def self.hud_csv_headers(version: nil)
    #   case version
    #   when '5.1'
    #     [
    #       :SiteID,
    #       :ProjectID,
    #       :CoCCode,
    #       :PrincipalSite,
    #       :Geocode,
    #       :Address,
    #       :City,
    #       :State,
    #       :ZIP,
    #       :DateCreated,
    #       :DateUpdated,
    #       :UserID,
    #       :DateDeleted,
    #       :ExportID
    #     ].freeze
    #   when '6.11', '6.12'
    #     [
    #       :GeographyID,
    #       :ProjectID,
    #       :CoCCode,
    #       :InformationDate,
    #       :Geocode,
    #       :GeographyType,
    #       :Address1,
    #       :Address2,
    #       :City,
    #       :State,
    #       :ZIP,
    #       :DateCreated,
    #       :DateUpdated,
    #       :UserID,
    #       :DateDeleted,
    #       :ExportID,
    #     ].freeze
    #   when '2020'
    #     [
    #       :GeographyID,
    #       :ProjectID,
    #       :CoCCode,
    #       :InformationDate,
    #       :Geocode,
    #       :GeographyType,
    #       :Address1,
    #       :Address2,
    #       :City,
    #       :State,
    #       :ZIP,
    #       :DateCreated,
    #       :DateUpdated,
    #       :UserID,
    #       :DateDeleted,
    #       :ExportID,
    #     ].freeze
    #   else
    #     [
    #       :GeographyID,
    #       :ProjectID,
    #       :CoCCode,
    #       :InformationDate,
    #       :Geocode,
    #       :GeographyType,
    #       :Address1,
    #       :Address2,
    #       :City,
    #       :State,
    #       :ZIP,
    #       :DateCreated,
    #       :DateUpdated,
    #       :UserID,
    #       :DateDeleted,
    #       :ExportID,
    #     ].freeze
    #   end
    # end

    def self.related_item_keys
      [:ProjectID]
    end

    def name
      "#{self.Address} #{self.City}"
    end

    # when we export, we always need to replace GeographyID with the value of id
    # and ProjectID with the id of the related project
    def self.to_csv(scope:)
      attributes = self.hud_csv_headers.dup
      headers = attributes.clone
      attributes[attributes.index(:GeographyID)] = :id
      attributes[attributes.index(:ProjectID)] = 'project.id'

      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map do |attr|
            attr = attr.to_s
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
