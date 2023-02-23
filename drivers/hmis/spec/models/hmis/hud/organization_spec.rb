require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Organization, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  let!(:organization) { create :hmis_hud_organization }
  before(:each) do
    create(:hmis_hud_project, organization: organization, data_source: organization.data_source)
  end

  it 'preserves shared data after destroy' do
    organization.destroy
    organization.reload

    [
      :user,
      :data_source,
    ].each do |assoc|
      expect(organization.send(assoc)).to be_present, "expected #{assoc} to be present"
    end
  end

  it 'destroys dependent data' do
    organization.reload
    [
      :projects,
    ].each do |assoc|
      expect(organization.send(assoc)).to be_present, "expected #{assoc} to be present"
    end

    organization.destroy
    organization.reload

    [
      :projects,
    ].each do |assoc|
      expect(organization.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
    end
  end
end
