###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :enrolled_disabled_report, class: 'GrdaWarehouse::WarehouseReports::EnrolledDisabledReport' do
    parameters do
      {
        'filter' => {
          'start' => 1.year.ago.to_date.to_s,
          'end' => Date.current.to_s,
          'sub_population' => 'all_clients',
          'disabilities' => ['1'],
          'project_types' => ['1'],
        },
      }
    end
    data { [] }
  end
end
