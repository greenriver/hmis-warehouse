BostonHmis::Application.routes.draw do
  scope :claims_reporting do
    root to: 'claims_reporting/home#index'
  end
end
