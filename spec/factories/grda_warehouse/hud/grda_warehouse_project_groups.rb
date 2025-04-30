# frozen_string_literal: true

FactoryBot.define do
  factory :project_group, class: 'GrdaWarehouse::ProjectGroup' do
    sequence(:name) { |n| "project-group#{n}" }
  end
end
