###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::CasVacancies < OpenStruct
  include ArelHelper
  attr_accessor :start_date
  attr_accessor :end_date

  def vacancies_by_route
    vacancy_scope.by_route.count
  end

  def vacancies_by_program
    vacancy_scope.by_program.count
  end

  def vacancies_by_sub_program
    vacancy_scope.by_sub_program.count
  end

  def vacancies_by_program_type
    vacancy_scope.by_program_type.count
  end

  def vacancies
    vacancy_scope.order(:vacancy_created_at)
  end

  def vacancy_scope
    GrdaWarehouse::CasVacancy.created_between(self[:start_date], self[:end_date])
  end
end
