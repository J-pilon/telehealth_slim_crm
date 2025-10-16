Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

  resources :patients do
    resources :messages, only: [:index, :show, :create, :edit, :update, :destroy]
    resources :tasks, only: [:index, :create, :update]
  end
end
