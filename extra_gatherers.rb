require "fastercsv"
require "mysql"

configure do
  $db_username = ENV["DB_USERNAME"] || "root"
  $db_password = ENV["DB_PASSWORD"]
  $db_database = ENV["DB_DATABASE"]
  $db_host = ENV["DB_HOST"]

  raise ArgumentError, "DB_DATABASE is unset" if $db_database.nil? || $db_database.to_s.empty?
end

def get_futures_queue_length(result)
  data = mysql("-e", '"SELECT COUNT(*) FROM futures WHERE futures.started_at IS NULL"')
  result["future_queue_length"] = data.split("\n").last.to_i
end

def get_next_futures(result)
  data = mysql("-e", '"SELECT type, args FROM futures WHERE futures.started_at IS NULL AND scheduled_at < NOW() ORDER BY priority, scheduled_at LIMIT 0,10"')
  result["next10"] = Array.new
  FasterCSV.parse(data, :col_sep => "\t", :headers => true, :return_headers => false) do |row|
    args = row[1].gsub("\\n", "\n")
    result["next10"] << {:type => row[0], :args => YAML.load(args)}
  end
end

def get_email_queue_length(result)
  data = mysql("-e", '"SELECT COUNT(*) FROM recipients WHERE recipients.sent_at IS NULL"')
  result["email_queue_length"] = data.split("\n").last.to_i
end

def get_rows_per_table(result)
  hash = result["rows_per_table"] = Hash.new {|h, k| h[k] = 0}
  tables = mysql("-e", '"SHOW TABLES"')
  cmds = []
  tables.split("\n").reject {|t| %w(schema_info engine_schema_info migrations_info).include?(t)}[1..-1].each do |tablename|
    tablename.chomp!
    cmds << ["-e", "\"SELECT COUNT(*) AS #{tablename}_count FROM #{tablename};\""]
  end

  data = mysql(cmds)
  tablename = nil
  data.split("\n").each do |row|
    case tablename
    when nil
      tablename = row
    else
      hash[tablename.sub("_count", "")] = row.to_i
      tablename = nil
    end
  end
end
