require "rails_helper"

RSpec.describe Admin::AvailableFileTagsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/admin/available_file_tags").to route_to("admin/available_file_tags#index")
    end

    it "routes to #new" do
      expect(:get => "/admin/available_file_tags/new").to route_to("admin/available_file_tags#new")
    end

    it "routes to #create" do
      expect(:post => "/admin/available_file_tags").to route_to("admin/available_file_tags#create")
    end

    it "routes to #destroy" do
      expect(:delete => "/admin/available_file_tags/1").to route_to("admin/available_file_tags#destroy", :id => "1")
    end

  end
end
