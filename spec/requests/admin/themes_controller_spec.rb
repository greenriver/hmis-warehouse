###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ThemesController, type: :request do
  let(:role) { create(:role, can_edit_theme: true) }
  let(:user) { create(:user).tap { |u| u.legacy_roles << role } }
  let!(:theme) { create(:theme) }
  let(:image_dir) { Rails.root.join('spec/fixtures/files/images') }
  let(:validation_message) { 'must be a PNG, JPEG, GIF, WebP or SVG image' }

  around do |example|
    original_client = ENV['CLIENT']
    ENV['CLIENT'] = 'test'
    example.run
  ensure
    ENV['CLIENT'] = original_client
  end

  before { sign_in user }

  def upload(body, name, type)
    Rack::Test::UploadedFile.new(StringIO.new(body), type, original_filename: name)
  end

  def preview_src(heading)
    Nokogiri::HTML(response.body).at_xpath("//h5[normalize-space(.)='#{heading}']/following-sibling::*[contains(@class, 'seal-image')]//img")&.[]('src')
  end

  describe 'PATCH update with a non-image file' do
    it 'does not store a non-image logo and shows the error' do
      html = upload('<!DOCTYPE html><html><body>x</body></html>', 'logo.html', 'text/html')

      patch admin_theme_path, params: { theme: { logo: html } }

      expect(theme.reload.logo).not_to be_attached
      expect(response.body).to include(validation_message)
    end

    it 'does not store a non-image print logo' do
      js = upload('console.log(1)', 'logo.js', 'text/javascript')

      patch admin_theme_path, params: { theme: { print_logo: js } }

      expect(theme.reload.print_logo).not_to be_attached
      expect(response.body).to include(validation_message)
    end

    it 'does not store a non-image HMIS logo' do
      js = upload('console.log(1)', 'logo.js', 'text/javascript')

      patch admin_theme_path, params: { theme: { hmis_logo: js } }

      expect(theme.reload.hmis_logo).not_to be_attached
      expect(response.body).to include(validation_message)
    end

    it 'keeps the stored logo and renders it in the preview after a rejected replacement' do
      theme.logo.attach(Rack::Test::UploadedFile.new(image_dir.join('test_logo.svg'), 'image/svg+xml'))
      original_checksum = theme.logo.blob.checksum

      patch admin_theme_path, params: { theme: { logo: upload('console.log(1)', 'logo.js', 'text/javascript') } }

      expect(theme.reload.logo.blob.checksum).to eq(original_checksum)
      expect(response.body).to include(validation_message)
      expect(preview_src('Current Logo')).to start_with('data:image/svg+xml;base64,')
      expect(response.body).not_to include('data:text/javascript')
    end

    it 'does not store HTML declared as image/png' do
      html = upload('<!DOCTYPE html><html><body>x</body></html>', 'logo.png', 'image/png')

      patch admin_theme_path, params: { theme: { logo: html } }

      expect(theme.reload.logo).not_to be_attached
      expect(response.body).to include(validation_message)
    end
  end

  describe 'PATCH update without file params' do
    it 'clears a blank hmis_origin and keeps the attached logo' do
      theme.update!(hmis_origin: 'hmis.example.test')
      theme.logo.attach(Rack::Test::UploadedFile.new(image_dir.join('test_logo.svg'), 'image/svg+xml'))

      patch admin_theme_path, params: { theme: { hmis_origin: '', css_file_contents: 'x' } }

      theme.reload
      expect(theme.hmis_origin).to be_blank
      expect(theme.css_file_contents).to eq('x')
      expect(theme.logo).to be_attached
    end
  end

  describe 'PATCH update by a user without can_edit_theme' do
    let(:role) { create(:role, can_edit_theme: false) }

    it 'refuses the request and does not attach the logo' do
      svg = Rack::Test::UploadedFile.new(image_dir.join('test_logo.svg'), 'image/svg+xml')

      patch admin_theme_path, params: { theme: { logo: svg } }

      expect(response).to have_http_status(:redirect)
      expect(response).not_to redirect_to(edit_admin_theme_path)
      expect(theme.reload.logo).not_to be_attached
    end
  end

  describe 'PATCH update with an image file' do
    it 'stores a JPEG print logo' do
      jpg = Rack::Test::UploadedFile.new(image_dir.join('test_photo.jpg'), 'image/jpeg')

      patch admin_theme_path, params: { theme: { print_logo: jpg } }

      expect(theme.reload.print_logo.blob.content_type).to eq('image/jpeg')
    end

    it 'stores an SVG logo' do
      svg = Rack::Test::UploadedFile.new(image_dir.join('test_logo.svg'), 'image/svg+xml')

      patch admin_theme_path, params: { theme: { logo: svg } }

      expect(theme.reload.logo.blob.content_type).to eq('image/svg+xml')
    end

    it 'stores a PNG HMIS logo' do
      png = Rack::Test::UploadedFile.new(image_dir.join('test_print_logo.png'), 'image/png')

      patch admin_theme_path, params: { theme: { hmis_logo: png } }

      expect(theme.reload.hmis_logo.blob.content_type).to eq('image/png')
    end
  end

  describe 'a theme that already holds a non-image logo' do
    before { store_unvalidated_logo(theme, 'logo', body: 'console.log(1)', filename: 'logo.js', content_type: 'text/javascript') }

    it 'can save a new image print logo' do
      png = Rack::Test::UploadedFile.new(image_dir.join('test_print_logo.png'), 'image/png')

      patch admin_theme_path, params: { theme: { print_logo: png } }

      expect(theme.reload.print_logo.blob.content_type).to eq('image/png')
    end

    it 'can replace the non-image logo with an image' do
      png = Rack::Test::UploadedFile.new(image_dir.join('test_print_logo.png'), 'image/png')

      patch admin_theme_path, params: { theme: { logo: png } }

      expect(theme.reload.logo.blob.content_type).to eq('image/png')
    end

    it 'renders the edit page without a preview of the stored non-image' do
      get edit_admin_theme_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('data:text/javascript')
    end

    it 'can still save the stylesheet' do
      patch admin_theme_path, params: { theme: { css_file_contents: ':root { --x: 1; }' } }

      expect(theme.reload.css_file_contents).to eq(':root { --x: 1; }')
    end
  end
end
