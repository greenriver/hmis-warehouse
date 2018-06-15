module Filters
  class MonthAndOrganization < ::Filters::DateRange::MonthDefault
    attribute :org, Integer, default: -> (s,_) {s.default_org}
    attribute :month, Integer, default: Date.today.month
    attribute :year, Integer, default: Date.today.year

    validates :org, presence: true

    def months
      @months = %w( January February March April May June July August September October November December ).each_with_index.to_a.map{ |m,i| [ m, i + 1 ] }
    end

    def organizations
        @organizations ||= GrdaWarehouse::Hud::Organization.residential.distinct.order(:OrganizationName)
      end

      def disambiguated_organizations
        @disambiguated_organizations ||= organizations.
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
      if disambiguated_organizations.has_key?(organization.name)
        organization.name
      elsif disambiguated_organizations.has_key?(disambiguated_name(organization))
        disambiguated_name(organization)
      else
        Rails.logger.error "this needs some work; there's an organization not individuated by its disambiguated name"
      end
    end

    def default_org
      GrdaWarehouse::Hud::Organization.residential.
      order(:OrganizationName).
      distinct.
      limit(1).
      pluck(:id, :OrganizationName).first.first rescue 0
    end

    def organization
      @organization ||= organizations.find org
    end

    def years
      ( earliest_year .. latest_year ).to_a
    end

    def earliest_year
      unless @earliest_year
        oldest_inventory = GrdaWarehouse::Hud::Inventory.order(:DateCreated).limit(1).pluck(:DateCreated).first
        @earliest_year = if oldest_inventory.present? then oldest_inventory.year else Date.today.year end
      end
      @earliest_year
    end

    def latest_year
      @latest_year ||= Date.today.year
    end

    validate do
      unless organization.present?
        errors.add :org, 'Organization required.'
      end
    end
  end
end