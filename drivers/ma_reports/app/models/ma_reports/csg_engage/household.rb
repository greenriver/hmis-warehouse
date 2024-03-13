###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class Household < Base
    attr_accessor :hoh_enrollment

    def initialize(hoh_enrollment)
      @hoh_enrollment = hoh_enrollment
    end

    field('Household Identifier') { hoh_enrollment.household_id }
    field('Temporary Family Number') { household_identifier }
    field('Annual Household Income') do
      GrdaWarehouse::Hud::IncomeBenefit.where(personal_id: enrollments_scope.pluck(:personal_id)).sum(:total_monthly_income) * 12
    end

    subfield('Address') do
      field('Apartment')
      field('CellPhone')
      field('City/Town') { coc&.city }
      field('ContactPhone')
      field('County')
      field('EmailAddress')
      field('EmergencyContactName')
      field('EmergencyContactPhone')
      field('Floor')
      field('Homeless (not Household Type)') { boolean_string(hoh_enrollment.living_situation == 1) }
      field('HomePhone')
      field('House #')
      field('SecondaryNumber')
      field('State') { coc&.state }
      field('StreetName')
      field('StreetPostDirection')
      field('StreetPreDirection')
      field('StreetSuffix')
      field('Unit Type')
      field('Zip Code') { coc&.zip }
      field('ZipPlus4')
    end

    subfield('CSBG Data') do
      field('Employee')
      field('Extra-Sensitive')
      field('Farmer')
      field('FoodStamps')
      field('Household Type')
      field('Housing Subsidy Type')
      field('Housing Type')
      field('HousingType', method: :housing_type_2)
      field('MigrantFarmer')
      field('Number in House') { enrollments_scope.count }
      field('SeasonalFarmer')
    end

    subfield('Other Address') do
      field('Apartment')
      field('CareOf')
      field('CityTown')
      field('Floor')
      field('HouseNumber')
      field('SecondaryDesignator')
      field('SecondaryNumber')
      field('State')
      field('StreetName')
      field('StreetPostDirection')
      field('StreetPreDirection')
      field('StreetSuffix')
      field('UseForMailings')
      field('ZipCode')
      field('ZipPlus4')
    end

    # field('Household Members') do
    #   result = []
    #   number = 1
    #   enrollments_scope.order(:personal_id).find_each do |enrollment|
    #     result << MaReports::CsgEngage::HouseholdMember.new(enrollment, number)
    #     number += 1
    #   end
    #   result
    # end

    private

    def enrollments_scope
      GrdaWarehouse::Hud::Enrollment.where(
        project_id: hoh_enrollment.project_id,
        household_id: hoh_enrollment.household_id,
      ).preload(client: [:income_benefits]).preload(:services)
    end

    def coc
      hoh_enrollment.project.project_cocs.first
    end
  end
end
