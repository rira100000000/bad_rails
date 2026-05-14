Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "books#index"

  # [BAD] 認証関連が member の collection アクションで散らかっている。 sessions リソースとして切り出すべき。
  get    "/signup",   to: "users#new",       as: :signup
  post   "/signup",   to: "users#create"
  get    "/login",    to: "sessions#new",    as: :login
  post   "/login",    to: "sessions#create"
  delete "/logout",   to: "sessions#destroy", as: :logout

  # [BAD] resources を使わず手書きで列挙 → ルートが膨らんでメンテ困難。
  resources :books do
    member do
      post :favorite
      delete :unfavorite
      post :buy           # [BAD] purchase は別リソースにすべき
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
