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
  let!(:project) { create :hmis_hud_project }
  before(:each) do
    create(:hmis_hud_enrollment, project: project, data_source: project.data_source)
    create(:hmis_hud_project_coc, project: project, data_source: project.data_source)
    create(:hmis_hud_funder, project: project, data_source: project.data_source)
    create(:hmis_hud_inventory, project: project, data_source: project.data_source)
  end

  it 'preserves shared data after destroy' do
    project.destroy
    project.reload

    [
      :data_source,
      :organization,
      :user,
    ].each do |assoc|
      expect(project.send(assoc)).to be_present, "expected #{assoc} to be present"
    end
  end

  it 'destroys dependent data' do
    project.reload
    [
      :enrollments,
      :project_cocs,
      :inventories,
      :funders,
    ].each do |assoc|
      expect(project.send(assoc)).to be_present, "expected #{assoc} to be present"
    end

    project.destroy
    project.reload

    [
      :enrollments,
      :project_cocs,
      :inventories,
      :funders,
    ].each do |assoc|
      expect(project.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
    end
  end
end
