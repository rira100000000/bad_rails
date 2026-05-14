Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "books#index"

  # [BAD-085]
  get    "/signup",   to: "users#new",       as: :signup
  post   "/signup",   to: "users#create"
  get    "/login",    to: "sessions#new",    as: :login
  post   "/login",    to: "sessions#create"
  delete "/logout",   to: "sessions#destroy", as: :logout

  # [BAD-086]
  resources :books do
    member do
      post :favorite
      delete :unfavorite
      post :buy
    end
  end

  resources :orders, only: [:index, :show, :create] do
    member do
      post :pay
      post :ship
      post :receive
      post :cancel
    end
  end

  resources :reviews, only: [:new, :create]
  resources :notifications, only: [:index] do
    member { post :read }
  end

  resources :users, only: [:show]
end
