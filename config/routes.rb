Rails.application.routes.draw do
  root "dashboard#index"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"
  resources :leads, except: :destroy do
    post :transition, on: :member
    post :convert, on: :member
  end
  resources :opportunities, only: %i[index show edit update] do
    post :transition, on: :member
  end
  post "actions", to: "actions#create"
  get "pipeline", to: "opportunities#pipeline"
  get "analytics", to: "analytics#index"
  resources :tasks, only: %i[index create edit update] do
    post :complete, on: :member
  end
  get "activity", to: "activities#index"
  get "settings", to: "settings#show"
  patch "settings", to: "settings#update"
  get "settings/password", to: "passwords#edit", as: :edit_password
  patch "settings/password", to: "passwords#update", as: :password
  post "settings/team", to: "settings#create_member", as: :team_members
  get "up", to: "health#show"
end
