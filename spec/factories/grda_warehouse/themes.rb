###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :theme, class: 'GrdaWarehouse::Theme' do
    client { 'test' }
  end

  factory :hmis_theme, parent: :theme do
    hmis_value { { 'palette' => { 'primary' => { 'main' => '#41596B' } } } }
  end
end
