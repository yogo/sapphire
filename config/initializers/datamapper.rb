require "dm-migrations"

config = YAML.load(File.new(File.join(Rails.root, "config", "database.yml")))

DataMapper.setup(:default, config[Rails.env])

DataMapper.finalize