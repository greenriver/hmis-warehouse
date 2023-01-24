RSpec.shared_context 'hmis base setup', shared_context: :metadata do
  let!(:ds1) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds1) } }
  let(:hmis_user) { user.related_hmis_user(ds1) }
  let(:u1) { Hmis::Hud::User.from_user(hmis_user) }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1, user: u1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }

  let(:edit_access_group) { create :edit_access_group }
  let(:view_access_group) { create :view_access_group }
end

RSpec.configure do |rspec|
  rspec.include_context 'hmis base setup', include_shared: true
end
