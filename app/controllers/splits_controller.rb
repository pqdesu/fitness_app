class SplitsController < ApplicationController
  before_action :set_split, only: [:show, :edit, :update, :destroy, :activate]

  def index
    @splits = current_user.splits.includes(:workout_days).order(:name)
    @active_split = current_user.current_split
  end

  def show
    @workout_days = @split.workout_days.order(:weekday, :id)
  end

  def new
    @split = current_user.splits.new
  end

  def create
    @split = current_user.splits.new(split_params)
    if @split.save
      redirect_to @split, notice: "Split created. Add its workout days next."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @split.update(split_params)
      redirect_to @split, notice: "Split updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def activate
    current_user.update!(active_split: @split)
    notice = "#{@split.name} is now your active split."
    # Changing it from the dashboard ("Change" on the active split card) returns there;
    # anywhere else the user stays on the page they were on.
    if from_dashboard?
      redirect_to root_path, notice:, status: :see_other
    else
      redirect_back fallback_location: splits_path, notice:, status: :see_other
    end
  end

  def destroy
    @split.destroy
    redirect_to splits_path, notice: "Split deleted.", status: :see_other
  end

  private

  def set_split
    @split = current_user.splits.find(params[:id])
  end

  def split_params
    params.expect(split: [:name])
  end
end
