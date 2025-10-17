Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

  # Sidekiq web UI (admin only)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  resources :patients do
    resources :messages, only: [:index, :show, :create, :edit, :update, :destroy]
    resources :tasks, only: [:index, :create, :update]
    collection do
      get :search
    end
  end

  resources :tasks, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      patch :complete
      patch :reopen
    end
  end
end
