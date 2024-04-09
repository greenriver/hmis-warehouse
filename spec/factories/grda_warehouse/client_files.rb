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
end
