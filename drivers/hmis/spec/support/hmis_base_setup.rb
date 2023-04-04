###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

RSpec.shared_context 'hmis base setup', shared_context: :metadata do
  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }

  let(:edit_access_group) do
    group = create :edit_access_group
    role = create(:hmis_role)
    group.access_controls.create(role: role)
    group
  end

  let(:view_access_group) do
    group = create :view_access_group
    role = create(:hmis_role_with_no_permissions, **Hmis::Role.permissions_with_descriptions.map { |k, v| v[:access] == [:viewable] ? k : nil }.compact.map { |p| [p, true] }.to_h)
    group.access_controls.create(role: role)
    group
  end
end

RSpec.shared_context 'file upload setup', shared_context: :metadata do
  let!(:tag) do
    GrdaWarehouse::AvailableFileTag.create!(
      name: 'Birth Certificate',
      group: 'Citizenship Verification',
      included_info: 'DoB, citizenship',
    )
  end

  let!(:tag2) do
    GrdaWarehouse::AvailableFileTag.create!(
      name: 'Social Security Card',
      group: 'Citizenship Verification',
      included_info: 'SSN',
    )
  end

  let!(:file) { File.open('drivers/hmis/spec/fixtures/files/TEST_PDF.pdf') }
  let!(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: 'TEST_PDF.pdf',
      content_type: 'application/pdf',
    )
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis base setup', include_shared: true
end
