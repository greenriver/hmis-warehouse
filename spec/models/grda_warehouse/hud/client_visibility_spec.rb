require 'rails_helper'
require 'shared_contexts/visibility_test_context'

RSpec.describe GrdaWarehouse::Hud::Client, type: :model do
  include_context 'visibility test context'
end
