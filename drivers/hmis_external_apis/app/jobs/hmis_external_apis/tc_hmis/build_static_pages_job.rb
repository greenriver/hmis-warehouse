
class HmisExternalApis::TcHmis::BuildStaticPagesJob
  def perform
    renderer = HmisExternalApis::TcHmis::StaticPagesController.renderer.new
    ['tchc_helpline', 'tchc_prevention_screening'].each do |page_id|
      content = renderer.render("hmis_external_apis/tc_hmis/static_pages/#{page_id}")
      puts content
    end
  end
end
