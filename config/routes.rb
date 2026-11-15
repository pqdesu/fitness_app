Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Shared exercise catalogue (admins manage it, everyone can browse it)
  resources :exercises, except: [:show]

  # Program: split -> workout days -> planned exercises
  resources :splits do
    resources :workout_days, only: [:new, :create]
  end
  resources :workout_days, only: [:show, :edit, :update, :destroy] do
    resources :workout_exercises, only: [:create]
    resources :workout_logs, only: [:create]
  end
  resources :workout_exercises, only: [:edit, :update, :destroy]

  # Recording: log -> logged exercises -> sets
  resources :workout_logs, only: [:index, :show, :update, :destroy] do
    resources :workout_log_exercises, only: [:create]
  end
  resources :workout_log_exercises, only: [:destroy] do
    resources :workout_sets, only: [:create]
  end
  resources :workout_sets, only: [:destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
