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

    field(:household_identifier) { hoh_enrollment.household_id }
    field(:temporary_family_number) { household_identifier }
    field(:city_or_town, label: 'City or Town') { coc&.city }
    field(:state) { coc&.state }
    field(:zip_code) { coc&.zip }
    field(:number_in_household, label: 'Number in Household') { enrollments_scope.count }
    field(:homeless) { boolean_string(hoh_enrollment.living_situation == 1) }

    field(:household_members) do
      result = []
      number = 1
      enrollments_scope.order(:personal_id).find_each do |enrollment|
        result << MaReports::CsgEngage::HouseholdMember.new(enrollment, number)
        number += 1
      end
      result
    end

    field(:annual_household_income) do
      GrdaWarehouse::Hud::IncomeBenefit.where(personal_id: enrollments_scope.pluck(:personal_id)).sum(:total_monthly_income) * 12
    end

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
