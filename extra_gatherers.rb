require "fastercsv"
require "mysql"

configure do
  $db_username = ENV["DB_USERNAME"] || "root"
  $db_password = ENV["DB_PASSWORD"]
  $db_database = ENV["DB_DATABASE"]
  $db_host = ENV["DB_HOST"]
end

def get_seconds_behind_master(result)
  data = mysql("-e", "SHOW SLAVE STATUS")
  result["seconds_behind_master"] = data.split("\n").grep(/seconds_behind_master/i).last.split(/\s+/).last.to_i
end
