require 'rails_helper'

RSpec.describe 'Redirect window routes to client', type: :routing do
  it 'redirects all window routes to the client controllers' do
    Rails.application.routes.routes.each do |route|
      if route.name.present? && (route.name.include?('_window_') || route.name =~ /^window_/)
        controller = route.requirements[:controller]
        expect(controller).to_not start_with('window/')
      end
    end
  end
end
