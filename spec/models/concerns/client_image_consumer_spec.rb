###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientImageConsumer, type: :model do
  describe '#image on a destination client' do
    let!(:client) { create :grda_warehouse_hud_client }
    let!(:project) { create :hud_project }

    def create_headshot(**attrs)
      # The factory resets tag_list from its tags transient on create, so tag afterward
      file = create :client_file, client: client, **attrs
      file.tag_list.add('Client Headshot')
      file.save!
      file
    end

    it 'returns an uploaded headshot' do
      headshot = create_headshot

      expect(client.image).to eq(headshot.as_thumb)
    end

    it 'ignores a confidential headshot' do
      create_headshot(confidential: true, data_source: project.data_source)

      expect(client.image).to eq(client.class.no_image_on_file_image)
    end

    it 'falls back to the newest non-confidential headshot' do
      public_headshot = create_headshot
      # A PDF has no thumbnail, so picking this file would yield the no-image placeholder
      pdf = Rack::Test::UploadedFile.new('spec/fixtures/files/test.pdf', 'application/pdf')
      create_headshot(confidential: true, data_source: project.data_source, client_file: pdf)

      expect(client.image).to eq(public_headshot.as_thumb)
    end
  end
end
