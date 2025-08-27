###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :client_file, class: 'GrdaWarehouse::ClientFile' do
    transient do
      tags { [] }
    end

    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    client_file { Rack::Test::UploadedFile.new('spec/fixtures/files/images/test_photo.jpg', 'image/jpeg') }
    name { 'Test File' }
    visible_in_window { true }

    before(:create) do |file, evaluator|
      file.tag_list = evaluator.tags.map(&:name)
    end
  end

  factory :client_file_coc_roi, class: 'GrdaWarehouse::ClientFile' do
    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    client_file { Rack::Test::UploadedFile.new('spec/fixtures/files/images/test_photo.jpg', 'image/jpeg') }
    name { 'CoC Roi' }
    visible_in_window { true }
  end

  factory :client_file_revoked_consent, class: 'GrdaWarehouse::ClientFile' do
    transient do
      tags { [] }
    end

    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    client_file { Rack::Test::UploadedFile.new('spec/fixtures/files/images/test_photo.jpg', 'image/jpeg') }
    name { 'Revoked Consent Form' }
    visible_in_window { true }
    consent_revoked_at { 1.day.ago }

    before(:create) do |file, evaluator|
      if evaluator.tags.empty?
        consent_form_tag = create :coc_roi_tag
        file.tag_list = [consent_form_tag.name]
      else
        file.tag_list = evaluator.tags.map(&:name)
      end
    end
  end

  factory :client_file_expanded_consent, class: 'GrdaWarehouse::ClientFile' do
    transient do
      tags { [] }
    end

    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    client_file { Rack::Test::UploadedFile.new('spec/fixtures/files/images/test_photo.jpg', 'image/jpeg') }
    name { 'Expanded Consent Form' }
    visible_in_window { true }
    consent_form_signed_on { 5.days.ago }
    consent_form_confirmed { true }

    before(:create) do |file, evaluator|
      if evaluator.tags.empty?
        consent_form_tag = create :coc_roi_tag
        file.tag_list = [consent_form_tag.name]
      else
        file.tag_list = evaluator.tags.map(&:name)
      end
    end
  end

  factory :client_file_partial_consent, class: 'GrdaWarehouse::ClientFile' do
    transient do
      tags { [] }
    end

    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    client_file { Rack::Test::UploadedFile.new('spec/fixtures/files/images/test_photo.jpg', 'image/jpeg') }
    name { 'Partial Consent Form' }
    visible_in_window { true }
    consent_form_signed_on { 5.days.ago }
    consent_form_confirmed { true }

    before(:create) do |file, evaluator|
      if evaluator.tags.empty?
        partial_consent_tag = create :available_file_tag,
                                     name: 'Partial Consent',
                                     consent_form: true,
                                     full_release: false
        file.tag_list = [partial_consent_tag.name]
      else
        file.tag_list = evaluator.tags.map(&:name)
      end
    end
  end
end
