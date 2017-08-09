require "rails_helper"

RSpec.describe Clients::VispdatsController, type: :routing do
  describe "routing" do

    skip "routes to #index" do
      expect(:get => "/vispdats").to route_to("vispdats#index")
    end

    skip "routes to #new" do
      expect(:get => "/vispdats/new").to route_to("vispdats#new")
    end

    skip "routes to #show" do
      expect(:get => "/vispdats/1").to route_to("vispdats#show", :id => "1")
    end

    skip "routes to #edit" do
      expect(:get => "/vispdats/1/edit").to route_to("vispdats#edit", :id => "1")
    end

    skip "routes to #create" do
      expect(:post => "/vispdats").to route_to("vispdats#create")
    end

    skip "routes to #update via PUT" do
      expect(:put => "/vispdats/1").to route_to("vispdats#update", :id => "1")
    end

    skip "routes to #update via PATCH" do
      expect(:patch => "/vispdats/1").to route_to("vispdats#update", :id => "1")
    end

    skip "routes to #destroy" do
      expect(:delete => "/vispdats/1").to route_to("vispdats#destroy", :id => "1")
    end

  end
end
