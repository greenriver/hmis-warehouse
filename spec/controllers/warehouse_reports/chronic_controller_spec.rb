require 'rails_helper'

RSpec.describe WarehouseReports::ChronicController, type: :controller do

  let(:user) { create :user }
  let(:admin_role) { create :admin_role }

  before(:each) do
    user.roles << admin_role
    authenticate(user)
  end

  describe "GET index" do
    context '.html' do
      before(:each) do
        get :index
      end

      it 'assigns @clients' do
        expect( assigns(:clients) ).to be_an ActiveRecord::Relation
      end
      it 'assigns @filter' do
        expect( assigns(:filter) ).to be_a Filters::Chronic
      end
      it 'assigns @so_clients' do
        expect( assigns(:so_clients) ).to be_an Array
      end
      it 'does not assign @most_recent_services' do
        expect( assigns(:most_recent_services) ).to be_nil
      end
      it 'renders index' do
        expect( response ).to render_template :index
        expect( response.content_type ).to eq 'text/html'
      end
    end

    context '.xlsx' do
      before(:each) do
        get :index, format: :xlsx
      end
      it 'assigns @most_recent_services' do
        expect( assigns(:most_recent_services) ).to be_a Hash
      end
      it 'renders index.xlsx' do
        expect( response ).to render_template :index
        expect( response.content_type ).to eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

end
