module SeedData
  # Finding or creating what the file names, by name: the equipment catalogue, an exercise of the
  # catalogue or of a user, and the equipment a lift or an exercise has (SeedData::Loader).
  module Catalogue
    private

    def find_or_create_equipment(item)
      named(EquipmentItem.where(kind: item["kind"]), item["name"]) || EquipmentItem.create!(item.slice("name", "kind"))
    end

    def find_or_create_exercise(scope, item)
      named(scope, item["name"]) ||
        scope.create!(item.slice("name", "muscle_group", "unilateral").merge(equipment_attributes(item)))
    end

    # A lift's or an exercise's equipment (Equipped::ATTRIBUTES), free weights when the file says none.
    def equipment_attributes(item)
      item.slice(*Equipped::ATTRIBUTES.map(&:to_s)).with_defaults("equipment" => "free_weights")
    end

    def named(scope, name)
      scope.where("LOWER(name) = ?", name.to_s.downcase).order(:id).first
    end
  end
end
