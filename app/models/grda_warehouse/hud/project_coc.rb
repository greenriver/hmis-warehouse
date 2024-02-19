###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class ProjectCoc < Base
    include HudSharedScopes
    include ::HmisStructure::ProjectCoc
    include ::HmisStructure::Shared
    include ArelHelper
    include RailsDrivers::Extensions
    require 'csv'

    attr_accessor :source_id

    self.table_name = 'ProjectCoC'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :project_cocs, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :project_cocs, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :project_cocs, optional: true
    has_many :geographies, class_name: 'GrdaWarehouse::Hud::Geography', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    has_many :inventories, class_name: 'GrdaWarehouse::Hud::Inventory', primary_key: [:ProjectID, :CoCCode, :data_source_id], foreign_key: [:ProjectID, :CoCCode, :data_source_id], inverse_of: :project_coc
    belongs_to :data_source
    has_one :lookup_coc, class_name: '::GrdaWarehouse::Lookups::CocCode', primary_key: :CoCCode, foreign_key: :coc_code, inverse_of: :project_coc
    has_one :overridden_lookup_coc, class_name: '::GrdaWarehouse::Lookups::CocCode', primary_key: :hud_coc_code, foreign_key: :coc_code, inverse_of: :overridden_project_coc

    # hide previous declaration of :importable, we'll use this one
    replace_scope :importable, -> do
      where(manual_entry: false)
    end

    # hide previous declaration of :in_coc, we'll use this one
    replace_scope :in_coc, ->(coc_code:) do
      coc_code = Array(coc_code)
      where(CoCCode: coc_code)
    end

    scope :with_coc, -> do
      where.not(CoCCode: nil)
    end

    scope :in_zip, ->(zip_code:) do
      zip_code = Array(zip_code)
      where(Zip: zip_code)
    end

    scope :in_place, ->(place:) do
      place = Array(place)
      where(arel_table[:City].lower.in(place.map(&:downcase)))
    end

    scope :in_county, ->(county:) do
      county = Array(county)
      zip_code_shapes.merge(
        GrdaWarehouse::Shape::ZipCode.counties,
      ).merge(
        GrdaWarehouse::Shape::County.county_by_name(county),
      )
    end

    # NOTE this isn't used for access on the on the project edit pages, so default
    # to the reporting permission
    # TODO: START_ACL cleanup after migration to ACLs
    scope :viewable_by, ->(user, permission: :can_view_assigned_reports) do
      return none unless user.present?

      if user.using_acls?
        return none unless user.send("#{permission}?")

        # if we have an access control with the All Data Sources system group
        # and the requested permission, return current scope
        # Otherwise, just return the project CoCs for the CoC Codes assigned
        all_data_sources = Collection.system_collection(:data_sources)
        if user.roles.merge(Role.where(permission => true)).merge(AccessControl.where(collection_id: all_data_sources.id)).exists?
          current_scope
        else
          group_ids = user.collections_for_permission(permission)
          return none if group_ids.empty?

          coc_codes = Collection.where(id: group_ids).pluck(:coc_codes).flatten
          GrdaWarehouse::Hud::ProjectCoc.in_coc(coc_code: coc_codes)
        end
      else
        if GrdaWarehouse::DataSource.can_see_all_data_sources?(user) # rubocop:disable Style/IfInsideElse
          current_scope
        elsif user.coc_codes.none?
          none
        else
          in_coc(coc_code: user.coc_codes)
        end
      end
      # END_ACL
    end

    scope :overridden, -> do
      scope = where(Arel.sql('1=0'))
      override_columns.each_key do |col|
        scope = scope.or(where.not(col => nil))
      end
      scope
    end

    # TODO: remove this
    # If any of these are not blank, we'll consider it overridden
    def self.override_columns
      {
        hud_coc_code: :CoCCode,
        geography_type_override: :GeographyType,
        geocode_override: :Geocode,
        zip_override: :Zip,
      }
    end

    def self.zip_code_shapes
      joins(<<~SQL)
        INNER JOIN shape_zip_codes ON ( shape_zip_codes.zcta5ce10 = "ProjectCoC"."Zip" OR shape_zip_codes.zcta5ce10 = "ProjectCoC"."zip_override")
      SQL
    end

    # TODO: replace calls to this with CoCCode
    def effective_coc_code
      self.CoCCode
    end

    # TODO: replace calls to this with Geocode
    def effective_geocode
      self.Geocode
    end

    def self.related_item_keys
      [:ProjectID]
    end

    def self.available_coc_codes
      distinct.pluck(coc_code_coalesce).reject(&:blank?).sort
    end

    def self.options_for_select(user:)
      # don't cache this, it's a class method
      viewable_by(user).
        distinct.
        pluck(coc_code_coalesce).
        reject(&:blank?).
        sort.
        map do |coc_code|
          [
            coc_code,
            coc_code,
          ]
        end
    end

    # TODO: replace calls to this with CoCCode
    def self.coc_code_coalesce
      pc_t[:CoCCode]
    end

    def for_export
      row = HmisCsvTwentyTwentyTwo::Exporter::ProjectCoc.adjust_keys(row)
      row
    end
  end
end
