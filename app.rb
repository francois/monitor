require "rubygems"
require "sinatra"
require "gchart"

get "/hits-per-domain" do
  hits = web0_data["hits_per_domain"]
  hits.each_pair do |scale, values|
    top10 = instance_variable_set("@top10_#{scale}", values.sort_by(&:last).reverse[0, 10])
    instance_variable_set("@hits_per_domain_#{scale}", Gchart.pie(:data => top10.map(&:last), :legend => top10.map(&:first), :size => "360x200"))
  end

  erb :hits_per_domain
end

helpers do
  def web0_data
    @web0_data ||= YAML.load_file("web0.yml")
  end
end
