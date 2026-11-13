###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Code do
  describe '.strip_old_copyright' do
    let(:old_block_2025) do
      <<~OLD
        ###
        # Copyright 2016 - 2025 Green River Data Analysis, LLC
        #
        # License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
        ###
      OLD
    end

    let(:old_block_2024) do
      <<~OLD
        ###
        # Copyright 2016 - 2024 Green River Data Analysis, LLC
        #
        # License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
        ###
      OLD
    end

    it 'removes old copyright at the top of a file' do
      content = old_block_2025 + "# frozen_string_literal: true\n\nclass Foo; end\n"
      result = described_class.strip_old_copyright(content)
      expect(result).not_to include('Green River Data Analysis')
      expect(result).to include('# frozen_string_literal: true')
      expect(result).to include('class Foo; end')
    end

    it 'removes the 2024 year variant' do
      content = old_block_2024 + "class Bar; end\n"
      result = described_class.strip_old_copyright(content)
      expect(result).not_to include('Green River Data Analysis')
      expect(result).to include('class Bar; end')
    end

    it 'removes old copyright when it follows a frozen_string_literal comment' do
      content = "# frozen_string_literal: true\n\n" + old_block_2025 + "class Baz; end\n"
      result = described_class.strip_old_copyright(content)
      expect(result).not_to include('Green River Data Analysis')
      expect(result).to include('# frozen_string_literal: true')
      expect(result).to include('class Baz; end')
    end

    it 'returns content unchanged when no old copyright is present' do
      content = described_class.copyright_header + "class Qux; end\n"
      result = described_class.strip_old_copyright(content)
      expect(result).to eq(content)
    end

    it 'returns content unchanged when file has no copyright at all' do
      content = "# frozen_string_literal: true\n\nclass Empty; end\n"
      result = described_class.strip_old_copyright(content)
      expect(result).to eq(content)
    end
  end
end
