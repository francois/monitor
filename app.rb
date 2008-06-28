require "rubygems"
require "sinatra"
require "elif_iterator"

$: << File.dirname(__FILE__)
require "core_ext/array"
require "base_gatherers"
require "extra_gatherers"

configure do
  $future_state_dir = ENV["FUTURE_STATE_DIR"]
end

get "/" do
  result = Hash.new
  get_identity(result)
  get_loadavg(result)
  get_disk_free_space(result)
  get_process_info(result)
  get_current_futures(result)

  header "Content-Type" => "text/x-yaml; charset=utf-8"
  result.to_yaml
end

def get_current_futures(result)
  hash = result["futures"] = Hash.new {|h, k| h[k] = Hash.new}
  Dir[File.join($future_state_dir, "future-state-*.log")].each do |file|
    instance_id = File.basename(file)[/\d+/].to_i
    line = File.read(file)
    fields = line.split(/\s+/, 5)
    hash[instance_id]["state"] = fields[1]
    hash[instance_id]["type"] = fields[3]
  end
end
