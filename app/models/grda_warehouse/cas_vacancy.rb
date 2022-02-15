###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class CasVacancy < GrdaWarehouseBase

    scope :created_between, -> (start_date, end_date) do
      where(vacancy_created_at: start_date..end_date)
    end

    scope :by_route, -> do
      group(:route_name).order(:route_name)
    end

    scope :by_program, -> do
      group(:program_name).order(:program_name)
    end

    scope :by_sub_program, -> do
      group(:sub_program_name).order(:sub_program_name)
    end

    scope :by_program_type, -> do
      group(:program_type).order(:program_type)
    end
  end
end
