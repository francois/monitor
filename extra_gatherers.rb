require "fastercsv"
require "mysql"

configure do
  $db_username = ENV["DB_USERNAME"] || "root"
  $db_password = ENV["DB_PASSWORD"]
  $db_database = ENV["DB_DATABASE"]
  $db_host = ENV["DB_HOST"]
end
