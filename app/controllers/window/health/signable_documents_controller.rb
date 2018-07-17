module Window::Health
  class SignableDocumentsController < IndividualPatientController
    include WindowClientPathGenerator
    include HealthCareplan

    before_action :set_client, except: [:signature]
    before_action :set_patient, except: [:signature]
    before_action :set_careplan, except: [:signature]
    before_action :set_medications, except: [:signature]
    before_action :set_problems, except: [:signature]

    # This supports signing without logging in:
    skip_before_action :authenticate_user!, only: [:signature]
    skip_before_action :require_some_patient_access!, only: [:signature]

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
      redirect_to polymorphic_path([:signature] + careplan_path_generator + [:signable_document], {client_id: @client.id, careplan_id: @careplan.id, id: @doc.id, email: 'patient@openpath.biz', hash: @doc.signer_hash('patient@openpath.biz')})
      # redirect_back fallback_location: client_health_careplans_path(@client)
    end

    def remind
      @careplan = @patient.careplans.find(params[:careplan_id])
      @doc      = @careplan.primary_signable_document

      @doc.remind!(email)

      flash.notice = "Reminded #{email}"
      redirect_back fallback_location: client_health_careplans_path(@client)
    end

    def signature
      @doc = Health::SignableDocument.find(params[:id])
      if current_user.present?
        @doc.update(expires_at: Health::SignableDocument.patient_expiration_window)
      end
      sign_out if params[:sign_out].present?

      if @doc.signer_hash(params[:email]) != params[:hash] || @doc.expired?
        not_authorized!
        return
      end

      @signature_request_url = @doc.signature_request_url(params[:email])
    rescue HelloSign::Error
      render 'error'
    end

    private

    def get_pdf
      pdf = careplan_combine_pdf_object
      file_name = 'care_plan'
      @pdf = pdf.to_pdf

    end

  end
end
