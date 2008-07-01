#!/usr/bin/ruby
require "rubygems"
require "cliaws"

DATA_DIR = ENV["DATA_DIR"] || "/var/www/frontend/data"
Cliaws.s3.list("xlsuite_production/ips/internal").each do |server|
  ip = Cliaws.s3.get(server)
  datafile = File.join(DATA_DIR, "#{File.basename(server)}.yml")
  `curl -s http://#{ip}:4987/ > #{datafile}`
end
