module SeedData
  # Merges the file's data with the database's: records are matched by KEYS, the database's
  # value wins for every field it has, and nothing only the file has is dropped.
  module Merge
    module_function

    # How the items of each list are matched. Every list called "exercises" (the catalogue, a
    # user's own, a day's plan, a workout's entries) is matched by name.
    KEYS = {
      "exercises" => ->(item) { item["name"].to_s.downcase },
      "users" => ->(item) { item["email"].to_s.downcase },
      "equipment" => ->(item) { [item["kind"], item["name"].to_s.downcase] },
      "set_tags" => ->(item) { item["name"].to_s.downcase },
      "splits" => ->(item) { item["name"] },
      "days" => ->(item) { item["weekday"] },
      "moves" => ->(item) { item["week_start"].to_s },
      "workouts" => ->(item) { [item["workout"], item["date"].to_s] },
      "sets" => ->(item) { item["number"] }
    }.freeze

    # The database's value wins for every field it has; lists are merged item by item.
    def record(old, new)
      old.merge(new) do |field, old_value, new_value|
        if KEYS.key?(field) && old_value.is_a?(Array) && new_value.is_a?(Array)
          list(field, old_value, new_value)
        else
          new_value
        end
      end
    end

    # The file's items in their order (each updated from the database when it is there too),
    # then the database's new items.
    def list(field, old, new)
      key = KEYS.fetch(field)
      new_by_key = new.index_by(&key)
      kept = old.map do |item|
        match = new_by_key.delete(key.call(item))
        match ? record(item, match) : item
      end
      kept + new_by_key.values
    end

    # Leaves out empty fields, so the file only says what is set.
    def compact(value)
      case value
      when Hash then value.filter_map { |field, item| [field, compact(item)] unless item.nil? || item == [] }.to_h
      when Array then value.map { |item| compact(item) }
      else value
      end
    end
  end
end
