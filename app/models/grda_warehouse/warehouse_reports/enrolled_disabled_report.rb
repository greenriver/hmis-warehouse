###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class EnrolledDisabledReport < Base
    validate :validate_parameters

    private def validate_parameters
      errors.add :start, 'Start Date is required' if parameters.try(:[], 'start').blank?
      errors.add :end, 'End Date is required' if parameters.try(:[], 'end').blank?
      errors.add :sub_population, 'Sub-population is required' if parameters.try(:[], 'sub_population').blank?
      errors.add :disabilities, 'At least one disability type is required' if parameters.try(:[], 'disabilities').blank?
      errors.add :project_types, 'At least one project type is required' if parameters.try(:[], 'project_types').blank?
    end
  end
end