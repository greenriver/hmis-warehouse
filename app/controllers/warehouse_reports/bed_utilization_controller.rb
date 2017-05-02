module WarehouseReports
  class BedUtilizationController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!

    def index
      @mo = MonthAndOrganization.new params[:mo]
      if @mo.valid?
        services      = GrdaWarehouse::ServiceHistory
        organizations = GrdaWarehouse::Hud::Organization
        projects      = GrdaWarehouse::Hud::Project
        st = services.arel_table
        ot = organizations.arel_table
        pt = projects.arel_table
        # you wouldn't think it would need to be as complicated as this, but Arel complained until I got it just right
        project_cols = %w( id data_source_id ProjectID ProjectName ProjectType).map(&:to_sym)
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

    class MonthAndOrganization < ModelForm
      attribute :org, Integer, default: GrdaWarehouse::Hud::Organization.residential.order(:OrganizationName).distinct.limit(1).pluck(:id, :OrganizationName).first.first
      attribute :month, Integer, default: Date.today.month
      attribute :year,  Integer, default: Date.today.year

      validates :org, presence: true

      def months
        @months = %w( January February March April May June July August September October November December ).each_with_index.to_a.map{ |m,i| [ m, i + 1 ] }
      end

      def organizations
        @organizations ||= GrdaWarehouse::Hud::Organization.
          residential.
          distinct.
          order(:OrganizationName).
          includes(:data_source).
          group_by(&:name).
          flat_map do |name, orgs|
            if orgs.many?
              orgs.map do |org|
                [ disambiguated_name(org), org.id ]
              end
            else
              [[ name, orgs.first.id ]]
            end
        end.to_h
      end

      def disambiguated_name(org)
        "#{org.name} < #{org.data_source.short_name}"
      end

      def organization_name
        if organizations.has_key?(organization.name)
          organization.name
        elsif organizations.has_key?(disambiguated_name(organization))
          disambiguated_name(organization)
        else
          Rails.logger.error "this needs some work; there's an organization not individuated by its disambiguated name"
        end
      end

      def organization
        @organization ||= GrdaWarehouse::Hud::Organization.find org
      end

      def years
        ( earliest_year .. latest_year ).to_a
      end

      def earliest_year
        @earliest_year ||= GrdaWarehouse::Hud::Inventory.order(:DateCreated).limit(1).pluck(:DateCreated).first.year
      end

      def latest_year
        @latest_year ||= Date.today.year
      end

      def range
        @range ||= begin
          day = Date.parse "#{year}-#{month}-1"
          day .. day.end_of_month
        end
      end

      def first
        range.begin
      end

      # fifteenth of relevant month
      def ides
        first + 14.days
      end

      def last
        range.end
      end

      validate do
        if year > latest_year
          errors.add :year, "The year cannot be greater than #{latest_year}."
        elsif year < earliest_year
          errors.add :year, "The year cannot be less than #{earliest_year}."
        end
        unless month.in? 1..12
          errors.add :month, "This does not appear to be a month of the year."
        end
      end
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
