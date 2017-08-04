module WarehouseReports
  class BedUtilizationController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!

    def index
      @mo = ::Filters::MonthAndOrganization.new params[:mo]
      if @mo.valid?
        console
        services      = GrdaWarehouse::ServiceHistory
        organizations = GrdaWarehouse::Hud::Organization
        projects      = project_source
        st = services.arel_table
        ot = organizations.arel_table
        pt = projects.arel_table
        # you wouldn't think it would need to be as complicated as this, but Arel complained until I got it just right
        project_cols = [:id, :data_source_id, :ProjectID, :ProjectName, project_source.project_type_column]
        @projects_with_counts = projects.
          joins( :service_history, :organization ).
          merge(organizations.residential).
          where( ot[:OrganizationID].eq @mo.organization.OrganizationID ).
          where( ot[:data_source_id].eq @mo.organization.data_source_id ).
          where( st[:date].between(@mo.range) ).
          group( *project_cols.map{ |cn| pt[cn] }, st[:date] ).
          order( pt[:ProjectName].asc, st[:date].asc ).
          select( *project_cols.map{ |cn| pt[cn] }, st[:date].as('date'), nf( 'COUNT', [nf( 'DISTINCT', [st[:client_id]] )] ).as('client_count') ).
          includes(:inventories).
          group_by(&:id)
      else
        @projects_with_counts = ( @mo.organization.projects.map{ |p| [ p, [] ] } rescue {} )
      end
      respond_to :html, :xlsx
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    
    def info project, projects_by_date, date
      ri = relevant_inventory project.inventories, date
      capacity = ri.try(&:BedInventory)
      clients = projects_by_date[date].try(&:client_count).to_i
      {
        capacity:         capacity,
        persons:          clients,
        percent_capacity: capacity.try{ |c| ( clients / c.to_f * 100 ).round(1) if c > 0 }
      }
    end
    helper_method :info

    def avg_info project, projects_by_date, range
      persons = []
      percent_capacity = []
      range.to_a.each do |date|
        i = info project, projects_by_date, date
        persons << i[:persons]
        percent_capacity << i[:percent_capacity]
      end
      percent_capacity = percent_capacity.compact
      {
        persons: ( persons.sum.to_f / persons.length ).round(1),
        percent_capacity: ( ( percent_capacity.sum.to_f / percent_capacity.length ).round(1) if percent_capacity.any? )
      }
    end
    helper_method :avg_info

    # find the inventory closest in time to the reference date
    # this might not be the approved way to deal with it -- perhaps we only want the closest preceding inventory -- but
    # our inventory information is exceedingly spotty
    def relevant_inventory inventories, date
      inventories = inventories.select{ |inv| inv.BedInventory.present? }
      if inventories.any?
        ref = date.to_time.to_i
        inventories.sort_by do |inv|
          ( ( inv.DateUpdated || inv.DateCreated ).to_time.to_i - ref ).abs
        end.first
      end
    end
    helper_method :relevant_inventory

  end
end
