require 'rails_helper'

RSpec.describe 'Legacy Controller Authorization', type: :controller do
  after(:each) do
    Rails.application.reload_routes!
  end

  let!(:user) { create :user }
  before(:each) do
    sign_in(user)

    klass = Class.new(ApplicationController) do
      before_action :require_can_view_projects!

      def authorized_action
        render plain: 'authorized success'
      end

      def handle_unauthorized_error(_error)
        head :forbidden
      end
    end

    @controller = klass.new

    stub_const('TestAuthController', klass)
    Rails.application.routes.draw do
      get 'authorized_action' => 'test_auth#authorized_action'
    end
  end

  it 'enforces authorization' do
    get :authorized_action
    expect(response).to have_http_status(:forbidden)
  end

  it 'allows access when authorized' do
    allow_any_instance_of(User).to receive(:can_view_projects?).and_return(true)
    get :authorized_action
    expect(response).to have_http_status(:success)
  end

  it 'does not have access to V2 authorization methods' do
    expect(@controller.respond_to?(:authorize_with)).to be false
  end
end
