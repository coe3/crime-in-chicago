begin
  config = YAML.load_file("config/database.yml")
rescue
  uri = URI.parse(ENV["DATABASE_URL"])
  config = {
    "production" => {
      "adapter"  => "postgres",
      "host"     => uri.host,
      "database" => uri.path.slice(1..-1),
      "username" => uri.username,
      "password" => uri.password
    }
  }

  raise "You must create a database.yml"
end

DB = Sequel.postgres(config[Sinatra::Application.environment.to_s].reject { |key, value|
  key == "adapter"
})

