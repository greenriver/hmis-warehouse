###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa::Generators::Fy2023::MissingDataConcern
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
    @missing_data[:missing_inventory_household_types] = missing_inventory_household_types(user)
    @missing_data[:missing_inventory_start_dates] = missing_inventory_start_dates(user)
    @missing_data[:missing_hmis_participation_start_dates] = missing_hmis_participation_start_dates(user)
    @missing_data[:invalid_hmis_participation_types] = invalid_hmis_participation_types(user)

    @missing_data[:missing_projects] = @missing_data.values.flatten.uniq.sort_by(&:first)
    @missing_data[:show_missing_data] = @missing_data[:missing_projects].any?
    @missing_data
  end

  private def missing_data_columns
    {
      project_name: p_t[:ProjectName].to_sql,
      org_name: o_t[:OrganizationName].to_sql,
      project_type: p_t[:ProjectType].to_sql,
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
      GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.joins(:organization).
      left_outer_joins(:funders).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      where(HousingType: nil).
      housing_type_required.
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)), # this is imperfect, but only look at projects with enrollments open during the past three years
    )
  end

  private def missing_geocodes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Geocode: nil),
    )
  end

  private def geography_types(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(GeographyType: nil),
    )
  end

  private def missing_zips(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(Zip: nil),
    )
  end

  private def operating_start_dates(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.joins(:organization).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      left_outer_joins(:funders).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      where(OperatingStartDate: nil),
    )
  end

  private def invalid_funders(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.joins(:organization).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      joins(:funders).
      distinct.
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)).
      where(f_t[:StartDate].eq(nil)),
    )
  end

  private def missing_coc_codes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::ProjectCoc.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(CoCCode: nil),
    )
  end

  private def missing_inventory_coc_codes(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Project.coc_funded.
      viewable_by(user, permission: :can_view_assigned_reports).
      where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types).
      joins(:project_cocs, :inventories, :organization).
      left_outer_joins(:funders).
      merge(GrdaWarehouse::Hud::ProjectCoc.where(pc_t[:CoCCode].not_eq(nil))).
      merge(GrdaWarehouse::Hud::Inventory.where(CoCCode: nil)).
      distinct,
    )
  end

  private def missing_inventory_household_types(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Inventory.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(HouseholdType: nil),
    )
  end

  private def missing_inventory_start_dates(user)
    missing_data_rows(
      GrdaWarehouse::Hud::Inventory.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(InventoryStartDate: nil),
    )
  end

  private def missing_hmis_participation_start_dates(user)
    missing_data_rows(
      GrdaWarehouse::Hud::HmisParticipation.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(HMISParticipationStatusStartDate: nil),
    )
  end

  private def invalid_hmis_participation_types(user)
    missing_data_rows(
      GrdaWarehouse::Hud::HmisParticipation.joins(project: :organization).
      left_outer_joins(project: :funders).
      distinct.
      merge(GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).coc_funded.hud_residential.where(ProjectType: HudLsa::Filters::LsaFilter.relevant_project_types)).
      where(ProjectID: GrdaWarehouse::Hud::Enrollment.open_during_range(@range).select(:ProjectID)). # this is imperfect, but only look at projects with enrollments open during the past three years
      where(HMISParticipationType: [nil, 99]),
    )
  end
end
