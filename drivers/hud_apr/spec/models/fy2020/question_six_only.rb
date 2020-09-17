require 'rails_helper'
require_relative 'apr_context.rb'
require_relative 'examples/question_six'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionSix, type: :model do
  include_context 'apr context'

  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  include_examples 'question six'
end
