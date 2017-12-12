require 'rails_helper'

RSpec.describe WarehouseReports::ChronicController, type: :controller do

  let(:user) { create :user }
  let(:admin_role) { create :admin_role }
  let!(:chronic_report) { create :chronic_report }
  
  before(:each) do
    user.roles << admin_role
    authenticate(user)
  end

  describe "GET index" do
    context 'when commit present' do
      before(:each) do
        get :index, commit: 'Run'
      end
      pending 'kicks off a job' do
        expect( Delayed::Job.count ).to eq 1
      end
      pending 'assigns @reports' do
        expect( assigns(:reports) ).to be_an ActiveRecord::Relation
      end
      pending 'renders index' do
        expect( response ).to render_template :index
      end
    end
  end

  describe 'GET show' do
    context '.html' do
      before(:each) do
        get :show, id: chronic_report.id
      end
      pending 'assigns @report' do
        expect( assigns(:report) ).to eq chronic_report
      end
      pending 'renders show.html' do
        expect( response ).to render_template :show
      end
    end
    context '.xlsx' do
      before(:each) do
        get :show, id: chronic_report.id, format: :xlsx
      end
      pending 'assigns @report' do
        expect( assigns(:report) ).to eq chronic_report
      end
      pending 'renders show.xlsx' do
        expect( response ).to render_template :show
        expect( response.content_type ).to eq 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

end
