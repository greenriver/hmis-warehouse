###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::Calculators
  class CovidVaccinationStatus
    DATA_FIELDS = [:member_id, :service_start_date, :procedure_code].freeze

    def initialize(member_ids)
      @member_ids = member_ids
    end

    def to_map
      @member_ids.map do |member_id|
        [
          member_id,
          vaccinations_for_member(member_id),
        ]
      end.to_h
    end

    def self.dashboard_sort_options
      nil
    end

    def sort_order(_column, _direction)
      nil
    end

    def types_from_claims(claims)
      claims&.map { |claim| vaccination_types[claim[:procedure_code]] }&.uniq&.join(', ')
    end

    def doses_from_claims(claims)
      doses = claims&.select { |claim| vaccination_doses[claim[:procedure_code]].present? }
      doses&.map { |dose| "#{vaccination_doses[dose[:procedure_code]]} on #{dose[:service_start_date]}" }&.join(', ')
    end

    def vaccinations_for_member(member_id)
      @vaccination_claims ||= begin
        vax_claims = ClaimsReporting::MedicalClaim.
          where(member_id: @member_ids, procedure_code: vaccination_types.keys + vaccination_doses.keys).
          pluck(*DATA_FIELDS).
          group_by(&:first).
          transform_values! { |claims| claims.map { |claim| DATA_FIELDS.zip(claim).to_h }.uniq { |claim| claim[:service_start_date] } }

        # Add in any additional EPIC data
        Health::Vaccination.
          where(medicaid_id: @member_ids).
          pluck(:medicaid_id, :vaccination_type, :vaccinated_on).
          group_by(&:first).
          each do |medicaid_id, epic_vaxes|
            epic_vaxes.reject { |(_, _, date)| vax_claims[medicaid_id]&.map { |claim| claim[:service_start_date] }&.include?(date) }.
              each do |epic_vax|
                vax_claims[medicaid_id] ||= []
                vax_claims[medicaid_id] << {
                  member_id: medicaid_id,
                  procedure_code: name_to_vaccination_types[epic_vax[1]],
                  service_start_date: epic_vax[2],
                }
              end
          end
        vax_claims
      end

      claims = @vaccination_claims[member_id]
      return [] unless claims.present?

      claims.map do |claim|
        {
          type: vaccination_types[claim[:procedure_code]],
          number: vaccination_doses[claim[:procedure_code]],
          date: claim[:service_start_date],
        }
      end
    end

    def name_to_vaccination_types
      @name_to_vaccination_types ||= {
        'Pfizer' => '91300',
        'Moderna' => '91301',
        'Janssen' => '91303',
      }.freeze
    end

    def vaccination_types
      @vaccination_types ||= {
        '91300' => 'Pfizer',
        '0001A' => 'Pfizer',
        '0002A' => 'Pfizer',
        '0003A' => 'Pfizer',
        '0004A' => 'Pfizer',
        '91301' => 'Moderna',
        '0011A' => 'Moderna',
        '0012A' => 'Moderna',
        '0013A' => 'Moderna',
        # '91302' => 'AstraZeneca',
        # '0021A' => 'AstraZeneca',
        # '0022A' => 'AstraZeneca',
        '91303' => 'Janssen',
        '0031A' => 'Janssen',
        # '91304' => 'Novavax',
        # '0041A' => 'Novavax',
        # '0042A' => 'Novavax',
        # '91305' => 'Pfizer (ready to use)',
        # '0051A' => 'Pfizer (ready to use)',
        # '0052A' => 'Pfizer (ready to use)',
        # '0053A' => 'Pfizer (ready to use)',
        # '0054A' => 'Pfizer (ready to use)',
        # '91306' => 'Moderna (low dose)',
        # '0064A' => 'Moderna (low dose)',
      }.freeze
    end

    def vaccination_doses
      @vaccination_doses ||= {
        # Pfizer
        '91300' => '', # Unknown dose
        '0001A' => 'first dose',
        '0002A' => 'second dose',
        '0003A' => 'third dose',
        '0004A' => 'booster',
        # Moderna
        '91301' => '', # Unknown dose
        '0011A' => 'first dose',
        '0012A' => 'second dose',
        '0013A' => 'third dose',
        # AstraZeneca
        # '91302' => '', # Unknown dose
        # '0021A' => 'first dose',
        # '0022A' => 'second dose',
        # Janssen
        '91303' => '', # Unknown dose
        '0031A' => 'single dose',
        # Novavax
        # '91304' => '', # Unknown dose
        # '0041A' => 'first dose',
        # '0042A' => 'second dose',
        # Pfizer (ready to use)
        # '91305' => '', # Unknown dose
        # '0051A' => 'first dose',
        # '0052A' => 'second dose',
        # '0053A' => 'third dose',
        # '0054A' => 'booster',
        # Moderna (low dose)
        # '91306' => '', # Unknown dose
        # '0064A' => 'booster',
      }.freeze
    end
  end
end
