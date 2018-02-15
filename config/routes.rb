Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/patients/record_id/:record_id', to: 'patients#record_id', as: 'record_id'

  resources :batch_health_pros, only: [:index, :new, :create, :show]
  resources :batch_invitation_codes, only: [:new, :create]
  resources :invitation_codes,  only: [:index, :show]
  resources :matches do
    member do
      patch :accept
    end
  end

  resources :matches do
    member do
      patch :accept
    end
  end

  get '/empi_lookup/new', to: 'empi#new', as: 'new_empi_lookup'
  get '/empi_lookup', to: 'empi#empi_lookup'

  resources :patients,  only: [:index, :show] do
    resources :invitation_code_assignments
  end

  resources :users, only: :show
  resource :settings, only: [:edit, :update]
  resources :uploads, only: :index

  root 'home#index'
end