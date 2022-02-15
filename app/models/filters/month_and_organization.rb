###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class MonthAndOrganization < ::Filters::DateRange::MonthDefault
    attribute :org, Integer, default: ->(s, _) { s.default_org }
    attribute :month, Integer, default: Date.current.month
    attribute :year, Integer, default: Date.current.year
    attribute :user, User, default: nil

    validates :org, presence: true

    def months
      @months = Date::MONTHNAMES.each_with_index.to_a.map { |m, i| [m, i + 1] }
    end

    def organizations
      @organizations ||= organization_scope.distinct.order(:OrganizationName).preload(projects: :inventories)
    end

    def disambiguated_organizations
      @disambiguated_organizations ||= organizations.
        includes(:data_source).
        group_by(&:name).
        flat_map do |name, orgs|
        if orgs.many?
          orgs.map do |org|
            [disambiguated_name(org), org.id]
          end
        else
          [[name, orgs.first.id]]
        end
      end.to_h
    end

    def disambiguated_name(org)
      "#{org.name} < #{org.data_source&.short_name}"
    end

    def organization_name
      if disambiguated_organizations.key?(organization.name)
        organization.name
      elsif disambiguated_organizations.key?(disambiguated_name(organization))
        disambiguated_name(organization)
      else
        Rails.logger.error "this needs some work; there's an organization not individuated by its disambiguated name"
      end
    end

    def default_org
      organization_scope.
        order(:OrganizationName).
        distinct.
        limit(1).
        pluck(:id, :OrganizationName).first.first
    rescue StandardError
      0
    end

    def organization
      @organization ||= begin
                          organizations.find org
                        rescue StandardError
                          organizations.first
                        end
    end

    def years
      (earliest_year .. latest_year).to_a
    end

    def earliest_year
      @earliest_year ||= GrdaWarehouse::Hud::Inventory.order(:DateCreated).limit(1).pluck(:DateCreated)&.first&.year || Date.current.year
    end

    def latest_year
      @latest_year ||= Date.current.year
    end

    def organization_scope
      if user.present?
        GrdaWarehouse::Hud::Organization.residential.viewable_by(user)
      else
        GrdaWarehouse::Hud::Organization.residential
      end
    end

    validate do
      errors.add :org, 'Organization required.' unless organization.present?
    end
  end
end
