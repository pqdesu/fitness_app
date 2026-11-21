module Admin
  # The tags users mark sets with (SetTag). Only an admin adds, renames or deletes them; deleting
  # one takes it off every set.
  class SetTagsController < ApplicationController
    before_action :require_admin!
    before_action :set_tag, only: [:edit, :update, :destroy]

    def index
      @tags = SetTag.order(:name)
      @tag = SetTag.new
    end

    def create
      @tag = SetTag.new(tag_params)
      if @tag.save
        redirect_to admin_set_tags_path, notice: "#{@tag.name} added."
      else
        @tags = SetTag.order(:name)
        render :index, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_set_tags_path, notice: "#{@tag.name} saved."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @tag.destroy!
      redirect_to admin_set_tags_path, notice: "#{@tag.name} deleted and taken off its sets.", status: :see_other
    end

    private

    def set_tag
      @tag = SetTag.find(params[:id])
    end

    def tag_params
      params.expect(set_tag: [:name])
    end
  end
end
