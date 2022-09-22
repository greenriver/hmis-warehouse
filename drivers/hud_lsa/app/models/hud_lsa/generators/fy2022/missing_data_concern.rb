###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2022::MissingDataConcern
  extend ActiveSupport::Concern

  def missing_data(user)
    @missing_data = {}
    @range = ::Filters::DateRange.new(start: Date.current - 3.years, end: Date.current)
    @missing_data[:missing_housing_type] = missing_housing_types(user)
    @missing_data[:missing_geocode] = missing_geocodes(user)
    @missing_data[:missing_geography_type] = geography_types(user)
    @missing_data[:missing_zip] = missing_zips(user)
    @missing_data[:missing_operating_start_date] = operating_start_dates(user)
    @missing_data[:invalid_funders] = invalid_funders(user)
    @missing_data[:missing_coc_codes] = missing_coc_codes(user)
    @missing_data[:missing_inventory_coc_codes] = missing_inventory_coc_codes(user)
    @missing_data[:missing_inventory_start_dates] = missing_inventory_start_dates(user)

    @missing_data[:missing_projects] = @missing_data.values.flatten.uniq.sort_by(&:first)
    @missing_data[:show_missing_data] = @missing_data[:missing_projects].any?
    @missing_data
  end

  private def missing_data_columns
    {
      project_name: p_t[:ProjectName].to_sql,
      org_name: o_t[:OrganizationName].to_sql,
      project_type: p_t[:computed_project_type].to_sql,
      funder: f_t[:Funder].to_sql,
      id: p_t[:id].to_sql,
      ds_id: p_t[:data_source_id].to_sql,
    }
  end

  private def missing_data_rows(scope)
    scope.pluck(*missing_data_columns.values).
      map do |row|
        row = Hash[missing_data_columns.keys.zip(row)]
        {
          project: "#{row[:org_name]} - #{row[:project_name]}",
          project_type: row[:project_type],
          id: row[:id], data_source_id:
          row[:ds_id]
        }
      end
  end

  private def missing_housing_types(user)
    # There are a few required project descriptor fields.  Without these the report won't run cleanly
    missing_data_rows(
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
      includes(:funders).
      where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
      where(HousingType: nil, housing_type_override: nil).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)), # this is imperfect, but only look at projects with enrollments open during the past three years
    )
  end

  private def missing_geocodes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Geocode: nil, geocode_override: nil),
    )
  end

  private def geography_types(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(GeographyType: nil, geography_type_override: nil),
    )
  end

  private def missing_zips(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Zip: nil, zip_override: nil),
    )
  end

  private def operating_start_dates(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
      includes(:funders).
      where(computed_project_type: [1, 2, 3, 8, 9, 10, 13, 4]).
      where(OperatingStartDate: nil, operating_start_date_override: nil),
    )
  end

  private def invalid_funders(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.joins(:organization).
      references(:funders).
      includes(:funders).
      distinct.
      # merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)).
      where(f_t[:Funder].not_in(::HUD.funding_sources.keys).or(f_t[:GrantID].eq(nil))),
    )
  end

  private def missing_coc_codes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(CoCCode: nil, hud_coc_code: nil),
    )
  end

  private def missing_inventory_coc_codes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.coc_funded.
      viewable_by(user).
      where(computed_project_type: [1, 2, 3, 8, 9, 10, 13]).
      joins(:project_cocs, :inventories, :organization).
      includes(:funders).
      merge(
        GrdaWarehouse::Hud::ProjectCoc.where(
          pc_t[:CoCCode].eq(nil).and(pc_t[:hud_coc_code].not_eq(nil)).
          or(pc_t[:CoCCode].not_eq(nil)),
        ),
      ).
      merge(GrdaWarehouse::Hud::Inventory.where(CoCCode: nil, coc_code_override: nil)).
      distinct,
    )
  end

  private def missing_inventory_start_dates(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Inventory.joins(project: :organization).
      includes(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user).coc_funded.hud_residential).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(InventoryStartDate: nil, inventory_start_date_override: nil),
    )
  end
end
