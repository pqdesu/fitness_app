class SplitsController < ApplicationController
  before_action :set_split, only: [:show, :edit, :update, :destroy]

  def index
    @splits = current_user.splits.includes(:workout_days).order(:name)
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
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @split.update(split_params)
      redirect_to @split, notice: "Split updated."
    else
      render :edit, status: :unprocessable_entity
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
    params.require(:split).permit(:name)
  end
end
