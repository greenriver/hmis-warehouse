###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisExternalApis::StaticPagesController < ActionController::Base
  include ::HmisExternalApis::StaticPagesHelper
  skip_before_action :verify_authenticity_token

  layout 'hmis_external_apis/static_pages'
  # these pages have inline csp meta tags
  content_security_policy false

  def show
    # this is intended for development. See PublishStaticFormsJob for production usage
    raise unless Rails.env.development?

    if params[:from_db]
      page = HmisExternalApis::StaticPages::Form.order(:id).where(name: params[:template]).last!
      return render(html: page.content.html_safe)
    end

    (@title, @definition_nodes) = read_definition(params[:template]).values_at('name', 'item')
    @renderer =  HmisExternalApis::StaticPages::FormGenerator.new(self)

    #template = 'hmis_external_apis/static_pages/' + params[:template]
    #render template: template
  end

  def create
    raise unless Rails.env.development?

    HmisExternalApis::StaticPages::FormSubmission.create!(
      form_content_version: params['form_version'],
      submitted_at: Time.current,
      data: params.to_unsafe_h,
      spam_score: 0,
      object_key: SecureRandom.uuid,
    )
    render json: params
  end

  def read_definition(filename)
    filename = Rails.root.join("drivers/hmis_external_apis/lib/static_page_forms/#{filename}.json")
    data_hash = JSON.parse(File.read(filename))
  end
end
