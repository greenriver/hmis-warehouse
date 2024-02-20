BostonHmis::Application.routes.draw do
  scope(module: :hmis_external_apis) do
    scope(module: :ac_hmis) do
      post '/hmis_external_api/ac_hmis/referrals',
           to: 'referrals#create',
           as: 'hmis_external_apis_referrals',
           defaults: { format: 'json' }

      get '/hmis_external_api/ac_hmis/program_involvements',
          to: 'involvements#program',
          as: 'hmis_external_apis_program_involvements',
          defaults: { format: 'json' }

      get '/hmis_external_api/ac_hmis/client_involvements',
          to: 'involvements#client',
          as: 'hmis_external_apis_client_involvements',
          defaults: { format: 'json' }
    end
    if Rails.env.development?
      scope(module: :tc_hmis) do
        # testing only
        get '/hmis_external_api/tc_hmis/static_pages/:id',
            to: 'static_pages#show',
            as: 'hmis_external_tc_hmis_static_pages',
            defaults: { format: 'html' }
      end
    end
  end
end
