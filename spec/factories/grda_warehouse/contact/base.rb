# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_contact_base, class: 'GrdaWarehouse::Contact::Base' do
    association :user
    entity_id { 1 }
  end

  factory :grda_warehouse_contact_organization, class: 'GrdaWarehouse::Contact::Organization' do
    association :user
    association :Organization, factory: :hud_organization
  end

  factory :grda_warehouse_contact_project, class: 'GrdaWarehouse::Contact::Project' do
    association :user
    association :project, factory: :hud_project
    entity_id { project.id }
  end
end
