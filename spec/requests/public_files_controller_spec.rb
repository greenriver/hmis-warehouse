###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicFilesController, type: :request do
  let(:user) { create(:user) }

  before(:each) { sign_in(user) }

  describe 'GET /public_files/:id' do
    it 'sends the file under its original ActiveStorage filename' do
      file = GrdaWarehouse::PublicFile.new(name: 'test', content_type: 'image/png')
      file.public_file.attach(io: StringIO.new('x' * 200), filename: 'coc_map.png', content_type: 'image/png')
      file.save!

      get public_file_path(id: file.id)

      expect(response.headers['Content-Disposition']).to include('filename="coc_map.png"')
    end
  end
end
