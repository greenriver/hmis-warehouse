require 'rails_helper'
require_relative 'apr_context'
require_relative 'examples/question_seven'

RSpec.describe HudApr::Generators::Shared::Fy2020::QuestionSeven, type: :model do
  include_context 'apr context'

  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  include_examples 'question seven'
end
