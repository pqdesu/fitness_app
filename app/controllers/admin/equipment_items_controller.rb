module Admin
  # The equipment catalogue (EquipmentItem): the free weights, machines and machine types users
  # pick for a lift. Only an admin adds to it, renames or deletes; lifts keep the names they have.
  class EquipmentItemsController < ApplicationController
    before_action :require_admin!
    before_action :set_item, only: [:edit, :update, :destroy]

    def index
      @items = EquipmentItem.order(:name).group_by(&:kind)
      @item = EquipmentItem.new(kind: "free_weights")
    end

    def create
      @item = EquipmentItem.new(item_params)
      if @item.save
        redirect_to admin_equipment_items_path, notice: "#{@item.name} added to #{EquipmentItem::KINDS[@item.kind].downcase}."
      else
        @items = EquipmentItem.order(:name).group_by(&:kind)
        render :index, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @item.update(item_params)
        redirect_to admin_equipment_items_path, notice: "#{@item.name} saved."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @item.destroy!
      redirect_to admin_equipment_items_path, notice: "#{@item.name} deleted.", status: :see_other
    end

    private

    def set_item
      @item = EquipmentItem.find(params[:id])
    end

    def item_params
      params.expect(equipment_item: [:name, :kind])
    end
  end
end
