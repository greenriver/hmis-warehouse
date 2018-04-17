require 'rails_helper'

RSpec.describe Admin::AdministrativeEventsController, type: :controller do
  let!(:user) { create :user }
  let!(:role) { build :admin_role }
  let!(:administrative_event) { create :grda_warehouse_administrative_event}
  let!(:initial_administrative_event_count) { GrdaWarehouse::AdministrativeEvent.count }
  let!(:valid_attr) { {title: "New title", description: "New description", date: "Apr 30, 2018"} }
  let!(:invalid_attr) { {title: "", description: "New description", date: "Jan 1, 2010"} } #invalid because title is an empty string
  
  describe "GET #index" do
    context 'User with access to administrative events' do
      before(:each) do
        user.roles << role
        authenticate(user)
      end

      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'User with no access to administrative events' do
    
      before(:each) do
        #Neglect to assign admin role to user
        authenticate(user)
      end

      it "receives a redirect" do
        get :index
        expect(response).to have_http_status(:redirect)
      end
    end
  end
  
  describe "POST #create" do 
    before(:each) do
      user.roles << role
      authenticate(user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user) #Stub the instance method :current_user
    end
    
    context "with valid attributes" do
      before { post :create, grda_warehouse_administrative_event: attributes_for(:grda_warehouse_administrative_event) }
      
      it "creates administrative event" do
        expect( GrdaWarehouse::AdministrativeEvent.count ).to eq( initial_administrative_event_count + 1 )
      end
      
      it 'redirects to AdministrativeEvent/#show' do
        expect( response ).to redirect_to(admin_administrative_events_path )
      end
      
    end
    
    context "with invalid attributes" do
      before { post :create, grda_warehouse_administrative_event: invalid_attr } 
      
      it "does not save the new administrative_event" do   
          expect( GrdaWarehouse::AdministrativeEvent.count ).to eq( initial_administrative_event_count )
      end
    
      it "does not redirect" do
        expect(response).not_to be_redirect
      end
      
    end
  end
  
  describe "PATCH #update" do
    
    before(:each) do
      user.roles << role
      authenticate(user)
    end
    
    context "with valid attributes" do
      before do 
        patch :update, id: administrative_event.id, grda_warehouse_administrative_event: valid_attr
        administrative_event.reload
      end

      it "redirects to #show" do
        expect( response ).to redirect_to( admin_administrative_events_path )
      end
      
      it "updates title" do
        expect( administrative_event.title ).to eql valid_attr[:title]
      end
      
      it "updates description" do
        expect( administrative_event.description ).to eql valid_attr[:description]
      end
      
      it "updates date" do
        expect( administrative_event.date ).to_not eql attributes_for(:grda_warehouse_administrative_event)[:date]
      end
    end
    
    context "with invalid attributes" do
      before do 
        patch :update, id: administrative_event.id, grda_warehouse_administrative_event: invalid_attr
        administrative_event.reload
      end

      it "does not redirect" do
        expect(response).not_to be_redirect
      end
      
      it "does not update title" do
        expect( administrative_event.title ).to eql attributes_for(:grda_warehouse_administrative_event)[:title]
      end
      
      it "does not update description" do
        expect( administrative_event.description ).to eql attributes_for(:grda_warehouse_administrative_event)[:description]
      end
      
      it "does not update date" do
        expect( administrative_event.date ).to_not eql valid_attr[:date]
      end
    end

  end

  describe "#destroy" do
    
    before(:each) do
      user.roles << role
      authenticate(user)
      delete :destroy, id: administrative_event
    end

    it 'deletes the note' do 
      expect( GrdaWarehouse::AdministrativeEvent.count ).to eq( initial_administrative_event_count - 1 )
    end 
    
    it 'redirects to AdministrativeEvent/#show' do
      expect( response ).to redirect_to( admin_administrative_events_path )
    end
    
  end

end
