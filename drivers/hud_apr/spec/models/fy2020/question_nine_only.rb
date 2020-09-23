require 'rails_helper'
require_relative 'apr_context'
require_relative 'examples/question_nine.rb'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionNine, type: :model do
  include_context 'apr context'

  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  include_examples 'question nine'
end
