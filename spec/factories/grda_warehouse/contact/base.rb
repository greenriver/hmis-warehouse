# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_contact_base, class: 'GrdaWarehouse::Contact::Base' do
    association :user
    entity_id { 1 }
  end

  factory :grda_warehouse_contact_organization, class: 'GrdaWarehouse::Contact::Organization' do
    association :user
    association :entity, factory: :hud_organization
    entity_type { 'GrdaWarehouse::Hud::Organization' }
    entity_id { entity.id }
  end

  factory :grda_warehouse_contact_project, class: 'GrdaWarehouse::Contact::Project' do
    association :user
    association :entity, factory: :hud_project
    entity_id { entity.id }
  end

  factory :grda_warehouse_contact_user, class: 'GrdaWarehouse::Contact::User' do
    association :user
    entity_type { 'User' }
    entity_id { user.id }
  end
end
