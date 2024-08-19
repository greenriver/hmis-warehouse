###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class Household < Base
    attr_accessor :hoh_enrollment

    def initialize(hoh_enrollment)
      @hoh_enrollment = hoh_enrollment
    end

    field('Household Identifier') { [hoh_enrollment.id, hoh_enrollment.project.id, hoh_enrollment.data_source.id].join('') }

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
      # field('Homeless (not Household Type)') { boolean_string(hoh_enrollment.living_situation == 1) }
      field('Homeless (not Household Type)')
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
      field('FoodStamps') do
        boolean_string(@enrollments_scope.any? { |enrollment| enrollment.income_benefits.max_by(&:information_date)&.SNAP == 1 })
      end
      field('Household Type')
      field('Housing Subsidy Type') do
        next '6' unless [435, 421].include?(hoh_enrollment.living_situation)

        case hoh_enrollment.rental_subsidy_type
        when 419
          '2'
        when 433
          '1'
        when 434
          '4'
        when 439
          '3'
        when nil
          'U'
        else
          '5'
        end
      end
      field('Housing Type')
      field('HousingType', method: :housing_type_2)
      field('MigrantFarmer')
      field('Number in House') { enrollments_scope.count.to_s }
      field('SeasonalFarmer')
    end

    # subfield('Other Address') do
    #   field('Apartment')
    #   field('CareOf')
    #   field('CityTown')
    #   field('Floor')
    #   field('HouseNumber')
    #   field('SecondaryDesignator')
    #   field('SecondaryNumber')
    #   field('State')
    #   field('StreetName')
    #   field('StreetPostDirection')
    #   field('StreetPreDirection')
    #   field('StreetSuffix')
    #   field('UseForMailings')
    #   field('ZipCode')
    #   field('ZipPlus4')
    # end

    field('Household Members') do
      result = []
      number = 1
      enrollments_scope.order(:personal_id).find_each do |enrollment|
        result << MaReports::CsgEngage::ReportComponents::HouseholdMember.new(enrollment, number)
        number += 1
      end
      result
    end

    private

    def enrollments_scope
      @enrollments_scope ||= GrdaWarehouse::Hud::Enrollment.where(
        project_id: hoh_enrollment.project_id,
        household_id: hoh_enrollment.household_id,
      ).preload(:income_benefits, :services)
    end

    def coc
      @coc ||= hoh_enrollment.project.project_cocs.first
    end
  end
end
