require "rubygems"
require "sinatra"
require "core_ext/array"
require "elif_iterator"
require "base_gatherers"

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end
