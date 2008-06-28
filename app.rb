require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"

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

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end

def get_futures_queue_length(result)
  cmd = %w(mysql)
  cmd << "--batch"
  cmd << "--user=#{$db_username}" if $db_username
  cmd << "--password=#{$db_password}" if $db_password
  cmd << "--database=#{$db_database}" if $db_database
  cmd << "--host=#{$db_host}" if $db_host

  data = sh(cmd, "-e", '"SELECT COUNT(*) FROM futures WHERE futures.started_at IS NULL"')
  result["queue_length"] = data.split("\n").last.to_i
end

def sh(*args)
  cmd = args.flatten.join(" ")
  puts "$ %s" % cmd
  data = `#{cmd}`
  puts data.split("\n").map {|line| "> #{line}"}
  data
end
