namespace :news_sources do
  EXPORT_COLUMNS = %w[name url feed_url enabled multiple_feeds scan_interval list_order].freeze

  desc "Export news sources to JSON. Optionally set FILE=path/to/output.json"
  task export: :environment do
    path = ENV.fetch("FILE", Rails.root.join("db", "news_sources.json").to_s)
    data = NewsSource.order(:list_order).map { |s| s.attributes.slice(*EXPORT_COLUMNS) }
    File.write(path, JSON.pretty_generate(data))
    puts "Exported #{data.size} sources to #{path}"
  end

  desc "Import news sources from JSON. Optionally set FILE=path/to/input.json"
  task import: :environment do
    path = ENV.fetch("FILE", Rails.root.join("db", "news_sources.json").to_s)
    abort "File not found: #{path}" unless File.exist?(path)
    data = JSON.parse(File.read(path))
    created = 0
    updated = 0
    data.each do |attrs|
      source = NewsSource.find_or_initialize_by(name: attrs["name"])
      is_new = source.new_record?
      source.assign_attributes(attrs)
      source.save!
      is_new ? created += 1 : updated += 1
    end
    puts "Done — #{created} created, #{updated} updated"
  end
end