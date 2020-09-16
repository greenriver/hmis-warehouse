require 'rails_helper'
require_relative 'apr_context.rb'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionSix, type: :model do
  describe 'Q6' do
    include_context 'apr context'

    before(:all) do
      setup(default_setup_path)
      HudApr::Generators::Shared::Fy2020::QuestionSix.new(options: default_options).run!
    end

    after(:all) do
      cleanup
    end

    it 'runs' do
      raise 'hi'
    end
  end
end
