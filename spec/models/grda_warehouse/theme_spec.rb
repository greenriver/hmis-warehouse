require 'rails_helper'

RSpec.describe GrdaWarehouse::Theme, type: :model do
  describe 'HMIS theme validation' do
    # cruft (non-HMIS themes that should not affect validation)
    let!(:wh_theme1) { create(:theme) }
    let!(:wh_theme2) { create(:theme, hmis_value: '') } # should be treated as non-HMIS theme

    before(:all) do
      ENV['CLIENT'] = 'test'
    end

    context 'when there are multiple HMIS themes with nil origin' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }

      it 'is invalid' do
        expect(theme1).to be_invalid
        expect(theme2).to be_invalid
      end
    end

    context 'when there are multiple HMIS themes with the same origin' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: 'test.dev') }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: 'test.dev') }

      it 'is invalid' do
        expect(theme1).to be_invalid
        expect(theme2).to be_invalid
      end
    end

    context 'when there are multiple HMIS themes with different origins' do
      let!(:theme1) { create(:hmis_theme, :skip_validate, hmis_origin: 'test1.dev') }
      let!(:theme2) { create(:hmis_theme, :skip_validate, hmis_origin: 'test2.dev') }
      let!(:default_theme) { create(:hmis_theme, :skip_validate, hmis_origin: nil) }

      it 'is valid' do
        expect(theme1).to be_valid
        expect(theme2).to be_valid
        expect(default_theme).to be_valid
      end

      it 'chooses specific theme for origin (test1.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin(theme1.hmis_origin)).to eq(theme1)
      end

      it 'chooses specific theme for origin (test2.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin(theme2.hmis_origin)).to eq(theme2)
      end

      it 'chooses default theme for origin (test3.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test3.dev')).to eq(default_theme)
      end
    end

    context 'when there is only a default theme' do
      let!(:default_theme) { create(:hmis_theme, hmis_origin: nil) }

      it 'chooses default theme for origin' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test1.dev')).to eq(default_theme)
      end
    end

    context 'when there is only a specific theme for test1.dev' do
      let!(:theme1) { create(:hmis_theme, hmis_origin: 'test1.dev') }

      it 'chooses specific theme for origin (test1.dev)' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test1.dev')).to eq(theme1)
      end
      it 'fails to find theme for different origin' do
        expect(GrdaWarehouse::Theme.hmis_theme_for_origin('test2.dev')).to eq(nil)
      end
    end
  end
end
