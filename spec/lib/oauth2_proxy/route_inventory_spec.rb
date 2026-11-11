###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth2Proxy::RouteInventory do
  describe '.auth_for' do
    it 'reports user auth for an ApplicationController action that keeps authenticate_user!' do
      controller = Class.new(ApplicationController)

      expect(described_class.auth_for(controller, :index)).to eq(:user)
    end

    it 'reports user auth for an Hmis::BaseController action that keeps authenticate_hmis_user!' do
      controller = Class.new(Hmis::BaseController)

      expect(described_class.auth_for(controller, :show)).to eq(:user)
    end

    it 'reports no auth when authenticate_user! is skipped for every action' do
      controller = Class.new(ApplicationController) { skip_before_action :authenticate_user! }

      expect(described_class.auth_for(controller, :index)).to eq(:none)
    end

    it 'skips user auth only for the actions listed in only:' do
      controller = Class.new(ApplicationController) { skip_before_action :authenticate_user!, only: [:show] }

      expect([described_class.auth_for(controller, :show), described_class.auth_for(controller, :index)]).
        to eq([:none, :user])
    end

    it 'skips user auth for every action except those listed in except:' do
      controller = Class.new(ApplicationController) { skip_before_action :authenticate_user!, except: [:index] }

      expect([described_class.auth_for(controller, :show), described_class.auth_for(controller, :index)]).
        to eq([:none, :user])
    end

    it 'reports no auth when a proc condition can switch authenticate_user! off' do
      controller = Class.new(ApplicationController) { skip_before_action :authenticate_user!, if: -> { false } }

      expect(described_class.auth_for(controller, :index)).to eq(:none)
    end

    it 'reports machine auth for a bearer-token Idp::JwtApiController action' do
      controller = Class.new(Idp::JwtApiController)

      expect(described_class.auth_for(controller, :index)).to eq(:machine)
    end

    it 'reports machine auth for an HmisExternalApis::BaseController action' do
      controller = Class.new(HmisExternalApis::BaseController)

      expect(described_class.auth_for(controller, :create)).to eq(:machine)
    end

    it 'reports no auth for an ActionController::Base action with no auth filter' do
      controller = Class.new(ActionController::Base)

      expect(described_class.auth_for(controller, :show)).to eq(:none)
    end
  end

  describe '#routes' do
    let(:route_set) do
      ActionDispatch::Routing::RouteSet.new.tap do |set|
        set.draw do
          get 'public_agencies', to: 'public_agencies#index'
          get 'clients/:id', to: 'clients#show'
          get 'no_controller', to: 'no_such_thing#index'
          get 'moved', to: redirect('/')
        end
      end
    end

    it 'classifies controller routes and leaves out routes with no loadable controller' do
      routes = described_class.new(route_set).routes

      expect(routes.map { |route| [route.verb, route.path, route.endpoint, route.auth] }).to contain_exactly(
        ['GET', '/public_agencies', 'public_agencies#index', :none],
        ['GET', '/clients/:id', 'clients#show', :user],
      )
    end
  end

  describe described_class::Route do
    def route(path_spec)
      described_class.new(verb: 'GET', path_spec: path_spec, endpoint: 'x#y', auth: :none)
    end

    it 'samples a path with optional segments dropped and with them filled in' do
      expect(route('/reports(/:year(/:month))(.:format)').sample_paths).
        to eq(['/reports', '/reports/1/1.json'])
    end

    it 'fills glob segments' do
      expect(route('/files/*object_key').sample_paths).to eq(['/files/a/b'])
    end

    it 'is matched by a pattern that accepts only the .json form' do
      json_only = [Regexp.new('^/hmis/user\.json$')]

      expect([route('/hmis/user(.:format)').matched_by?(json_only), route('/hmis/users(.:format)').matched_by?(json_only)]).
        to eq([true, false])
    end
  end
end
