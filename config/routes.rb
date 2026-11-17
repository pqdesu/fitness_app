Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  root to: "pages#home"

  # Exercises: the shared catalogue (admins manage it) and each user's own exercises
  resources :exercises, except: [:show]

  # Program: split -> workout days (one per weekday) -> exercises
  resources :splits do
    # Makes this the split the dashboard follows
    patch :activate, on: :member
    resources :workout_days, only: [:new, :create]
    # A workout on another weekday for this week only; deleting goes back to the plan
    resource :week_move, only: [:create, :destroy]
  end
  resources :workout_days, only: [:show, :edit, :update, :destroy] do
    resources :workout_exercises, only: [:create]
  end
  # Opening an exercise shows today's sets; adding a set there logs it under today's workout.
  resources :workout_exercises, only: [:show, :update, :destroy] do
    resources :workout_sets, only: [:create]
  end

  # Recording: log -> logged exercises -> sets. new and create start a workout that is not in a split.
  resources :workout_logs, only: [:index, :show, :new, :create, :update, :destroy] do
    resources :workout_log_exercises, only: [:create]
  end
  resources :workout_log_exercises, only: [:edit, :update, :destroy] do
    resources :workout_sets, only: [:create]
  end
  resources :workout_sets, only: [:update, :destroy]

  # Admin only: the accounts (make or unmake an admin, delete a user)
  namespace :admin do
    resources :users, only: [:index, :update, :destroy]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
