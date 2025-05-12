FactoryBot.define do
  factory :access_control_upload do
    user { User.system_user }
    after(:build) do |acl_import|
      acl_import.file.attach(io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'access_control_imports', 'access_control_upload.xlsx')), filename: 'access_control_upload.xlsx', content_type: 'spec/fixtures/files/access_control_imports/access_control_upload.xlsx')
    end
  end
end
