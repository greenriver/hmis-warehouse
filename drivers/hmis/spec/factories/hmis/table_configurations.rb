###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_table_configuration, class: 'Hmis::TableConfiguration' do
    association :data_source, factory: :hmis_data_source
    columns { [] }
    filters { [] }
  end

  factory :hmis_table_configuration_ce_waitlist, class: 'Hmis::TableConfiguration', parent: :hmis_table_configuration do
    table_key { 'ce_waitlist' }
    trait :with_columns do
      columns do
        [
          {
            'key' => 'cde.custom_assessment.my_household_type',
            'type' => 'string',
            'label' => 'Household Type',
          },
        ]
      end
    end
    trait :with_filters do
      filters do
        [
          {
            'key' => 'cde.custom_assessment.my_household_type',
            'label' => 'Household Type',
            'type' => 'select',
            'options' => [
              { 'code' => 'Household with children' },
              { 'code' => 'Household without children' },
            ],
          },
        ]
      end
    end
  end
end
