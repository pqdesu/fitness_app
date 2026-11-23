module SeedData
  # A cardio exercise's rows (incline, speed, time) in the file: written by the Dumper, read by the
  # Loader, matched by their number as sets are.
  module Cardio
    private

    # Only an exercise with cardio rows says so, so the entries already in the file stay as they are.
    def cardio_data(entry)
      return {} if entry.cardio_entries.empty?

      { "cardio" => entry.cardio_entries.map do |row|
        { "number" => row.entry_number, "incline" => row.incline&.to_s("F"), "speed" => row.speed&.to_s("F"),
          "seconds" => row.duration_seconds }
      end }
    end

    def load_cardio(entry, rows)
      Array(rows).each do |row|
        next if entry.cardio_entries.exists?(entry_number: row["number"])

        entry.cardio_entries.create!(entry_number: row["number"], duration_seconds: row["seconds"],
                                     incline: row["incline"] && BigDecimal(row["incline"].to_s),
                                     speed: row["speed"] && BigDecimal(row["speed"].to_s))
      end
    end
  end
end
