Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Exercises: the shared catalogue (admins manage it) and each user's own exercises
  resources :exercises, except: [:show]

  # Program: split -> workout days (one per weekday) -> exercises
  resources :splits do
    resources :workout_days, only: [:new, :create]
  end
  resources :workout_days, only: [:show, :edit, :update, :destroy] do
    resources :workout_exercises, only: [:create]
  end
  # Opening an exercise shows today's sets; adding a set there logs it under today's workout.
  resources :workout_exercises, only: [:show, :update, :destroy] do
    resources :workout_sets, only: [:create]
  end

  # Recording: log -> logged exercises -> sets
  resources :workout_logs, only: [:index, :show, :update, :destroy] do
    resources :workout_log_exercises, only: [:create]
  end
  resources :workout_log_exercises, only: [:edit, :update, :destroy] do
    resources :workout_sets, only: [:create]
  end
  resources :workout_sets, only: [:destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
