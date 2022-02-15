###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class EnrolledDisabledReport < Base
    validate :validate_parameters

    private def validate_parameters
      # parameters are stored in the db nested in 'filter', so we need to accept both formats
      params = parameters['filter'] || parameters
      errors.add :start, 'Start Date is required' if params.try(:[], 'start').blank?
      errors.add :end, 'End Date is required' if params.try(:[], 'end').blank?
      errors.add :sub_population, 'Sub-population is required' if params.try(:[], 'sub_population').blank?
      errors.add :disabilities, 'At least one disability type is required' if params.try(:[], 'disabilities').blank?
      errors.add :project_types, 'At least one project type is required' if params.try(:[], 'project_types').blank?
    end
  end
end
