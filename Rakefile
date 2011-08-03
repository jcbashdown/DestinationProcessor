require 'rubygems'
require 'rake'
#require 'ruby-debug'
load "lib/DestinationProcessor.rb"

namespace :destination_processor do
  task :process, :taxonomy, :destinations, :output_path do |t, args|
    DestinationProcessor.process(args.taxonomy, args.destinations, args.output_path)
  end
end