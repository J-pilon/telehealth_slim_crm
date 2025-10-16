Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

  resources :patients do
    resources :messages, only: [:index, :create]
    resources :tasks, only: [:index, :create, :update]
  end
end
