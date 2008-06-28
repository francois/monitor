require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"
require "fastercsv"

configure do
  $db_username = ENV["DB_USERNAME"] || "root"
  $db_password = ENV["DB_PASSWORD"]
  $db_database = ENV["DB_DATABASE"]
  $db_host = ENV["DB_HOST"]
end

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)
  get_futures_queue_length(result)
  get_next_futures(result)
  get_email_queue_length(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
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

def mysql(*args)
  cmd = %w(mysql)
  cmd << "--batch"
  cmd << "--user=#{$db_username}" if $db_username
  cmd << "--password=#{$db_password}" if $db_password
  cmd << "--database=#{$db_database}" if $db_database
  cmd << "--host=#{$db_host}" if $db_host
  sh(cmd, args)
end

def sh(*args)
  cmd = args.flatten.join(" ")
  puts "$ %s" % cmd
  data = `#{cmd}`
  puts data.split("\n").map {|line| "> #{line}"}
  data
end
