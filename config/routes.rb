Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get    "login",  to: "users/sessions#new",     as: :new_user_session
    delete "users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  resources :posts do
    resources :replies, only: [ :create, :edit, :update, :destroy ]
    resource :like, only: [ :create, :destroy ]
    resource :rsvp, only: [ :create, :destroy ]
  end
  resource :category_follow, only: [ :create, :destroy ]
  resources :conversations, only: [ :index, :show, :new, :create ] do
    resources :messages, only: [ :create, :update ]
  end
  resources :notifications, only: [ :index ] do
    post :open, on: :member
    patch :mark_all_read, on: :collection
  end
  get "calendar", to: "calendars#show", as: :calendar
  get "my-activity", to: "activities#show", as: :my_activity
  root "posts#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  get "faq", to: "pages#faq"
  get "about",   to: "pages#about"
  get "contact", to: "pages#contact"
end
