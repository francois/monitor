require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)
  get_futures_queue_length(result)
  get_next_futures(result)
  get_email_queue_length(result)
  get_rows_per_table(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end
