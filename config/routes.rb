Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Signed out the landing page; signed in the Home page: today's workout (or on a rest day what to
  # train instead), this week, the month's calendar and recent workouts.
  root to: "pages#home"
  # The dashboard was its own page until it joined the Today page as Home; old links land there.
  get "dashboard", to: redirect("/")
  # The month of the dashboard's calendar: its totals, splits and exercises
  get "dashboard/month", to: "pages#month", as: :dashboard_month

  # Exercises: the shared catalogue (admins manage it) and each user's own exercises
  resource :preferences, only: :update

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
    # Planning an exercise for the day (from the split page)
    resources :workout_exercises, only: [:create]
    # Adding an exercise to that day's workout while training; the plan stays as it is
    resources :workout_log_exercises, only: [:create]
    # Starting the timer before anything is logged logs the workout
    resource :timer, only: [:create], controller: "workout_timers"
  end
  # Opening an exercise shows today's sets; adding a set there logs it under today's workout.
  resources :workout_exercises, only: [:show, :update, :destroy] do
    # Move to another place in the day's plan (dragged on the split page)
    patch :move, on: :member
    resources :workout_sets, only: [:create]
    # A cardio exercise's rows (incline, speed, time), its counterpart of sets
    resources :cardio_entries, only: [:create]
    # Starting a cardio exercise's timer before anything is logged logs the workout (as the workout timer does)
    resource :rest, only: [:create], controller: "rest_timers"
  end

  # Recording: log -> logged exercises -> sets. new and create start a workout that is not in a split.
  resources :workout_logs, only: [:index, :show, :new, :create, :update, :destroy] do
    resources :workout_log_exercises, only: [:create]
    # The workout timer: start or resume (create), pause, stop (destroy), correct the finish (edit, update)
    resource :timer, only: [:create, :edit, :update, :destroy], controller: "workout_timers" do
      post :pause
    end
  end
  resources :workout_log_exercises, only: [:edit, :update, :destroy] do
    # Move to another place in that workout (dragged, or Move up/down); the plan keeps its order
    patch :move, on: :member
    resources :workout_sets, only: [:create]
    resources :cardio_entries, only: [:create]
    # The rest timer between sets, and a cardio exercise's timer (the same two columns): Start (create),
    # Stop (update), throw it away (destroy)
    resource :rest, only: [:create, :update, :destroy], controller: "rest_timers"
  end
  resources :workout_sets, only: [:update, :destroy]
  resources :cardio_entries, only: [:update, :destroy]

  # Admin only: the accounts (make or unmake an admin, delete a user)
  namespace :admin do
    resources :users, only: [:index, :update, :destroy]
    # The equipment catalogue users pick a lift's equipment from
    resources :equipment_items, path: "equipment", except: [:show, :new]
    # The tags users mark sets with
    resources :set_tags, path: "tags", except: [:show, :new]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
