require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe Admin::AvailableFileTagsController, type: :request do
  # This should return the minimal set of attributes required to create a valid
  # GrdaWarehouse::AvailableFileTag. As you add validations to GrdaWarehouse::AvailableFileTag, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    build(:available_file_tag).attributes.with_indifferent_access
  end

  let(:invalid_attributes) do
    {
      somthing: 5,
    }
  end

  let(:user) { create(:user) }
  let(:admin)       { create(:user) }
  let(:admin_role)  { create :admin_role }
  let!(:no_data_source_access_group) { create :access_group }

  before(:each) do
    sign_in admin
    setup_access_control(admin, admin_role, no_data_source_access_group)
  end

  describe 'GET #index' do
    it 'assigns all available_file_tags as @available_file_tags' do
      available_file_tag = GrdaWarehouse::AvailableFileTag.create! valid_attributes
      get admin_available_file_tags_path
      expect(assigns(:available_file_tags)).to eq([available_file_tag])
    end
  end

  describe 'GET #new' do
    it 'assigns a new available_file_tag as @available_file_tag' do
      get new_admin_available_file_tag_path
      expect(assigns(:available_file_tag)).to be_a_new(GrdaWarehouse::AvailableFileTag)
    end
  end
end
