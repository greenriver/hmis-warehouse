module Window::Health
  #TDB: unsure about parent class.
  class SignableDocumentsController < IndividualPatientController
    include WindowClientPathGenerator
    before_action :set_client, except: [:signature]
    before_action :set_patient, except: [:signature]
    before_action :set_careplan, except: [:signature]

    # This supports signing without logging in:
    skip_before_action :authenticate_user!, :only => [:signature]
    skip_before_action :require_some_patient_access!, :only => [:signature]

    # TDB: Any special permission checking I need to do?

    def create
      @team = @careplan.team

      @signers = []
      @signers << { 'email': 'patient@openpath.biz', 'name': @patient.name }

      @doc = @careplan.signable_documents.build(signers: @signers, primary: true, user_id: current_user.id)

      @doc.pdf_content_to_upload = get_pdf

      if @doc.valid?
        @careplan.class.transaction do
          @careplan.signable_documents.where.not(id: @doc.id).update_all(primary: false)
          @doc.make_document_signable!
        end

        flash[:notice] = "Created a document (#{@doc.id}) for #{@doc.signers.map(&:email).join('; ')} to sign"
      else
        flash[:error] = "#{@doc.errors.full_messages.join('. ')}"
      end

      redirect_back fallback_location: client_health_careplans_path(@client)
    end

    def remind
      @careplan = @patient.careplans.find(params[:careplan_id])
      @doc      = @careplan.primary_signable_document

      @doc.remind!(email)

      flash.notice = "Reminded #{email}"
      redirect_back fallback_location: client_health_careplans_path(@client)
    end

    def signature
      sign_out if params[:sign_out].present?

      @doc = Health::SignableDocument.find(params[:id])

      if @doc.signer_hash(params[:email]) != params[:hash]
        not_authorized!
        return
      end

      @signature_request_url = @doc.signature_request_url(params[:email])
    rescue HelloSign::Error
      render 'error'
    end

    private

    # TDB: Need to DRY up this and CareplansController show method.
    # TDB: This just proves it works. Maybe it doesn't need to be over there
    # TDB: anymore?
    # TDB: "app/controllers/window/health/careplans_controller.rb
    def get_pdf
      @goal = Health::Goal::Base.new
      @readonly = false
      file_name = 'care_plan'
      # make sure we have the most recent-services and DME if
      # the plan is editable
      if @careplan.editable?
        @careplan.archive_services
        @careplan.archive_equipment
        @careplan.save
      end

      # Include most-recent SSM & CHA
      @form = @patient.self_sufficiency_matrix_forms.recent.first
      @cha = @patient.comprehensive_health_assessments.recent.first

      html = render_to_string('window/health/careplans/show.haml', layout: false)

      @pdf = WickedPdf.new.pdf_from_string(
        html,
        pdf: file_name,
        layout: false,
        encoding: "UTF-8",
        page_size: 'Letter',
        header: { html: { template: 'window/health/careplans/_pdf_header' }, spacing: 1 },
        footer: { html: { template: 'window/health/careplans/_pdf_footer'}, spacing: 5 },
      )
    end

    def set_careplan
      # TDB: Not confident in doing proper authorization here
      @careplan = @patient.careplans.find(params[:careplan_id])
    end
  end
end
