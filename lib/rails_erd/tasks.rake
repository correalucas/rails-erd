require 'graphviz/utils'

def say(message)
  puts message unless Rake.application.options.silent
end

namespace :erd do
  task :check_dependencies do
    include GraphViz::Utils
    unless find_executable("dot", nil)
      raise "Unable to find GraphViz's \"dot\" executable. Please " \
            "visit https://voormedia.github.io/rails-erd/install.html for installation instructions."
    end
  end

  task :options do
    (RailsERD.options.keys.map(&:to_s) & ENV.keys).each do |option|
      RailsERD.options[option.to_sym] = case ENV[option]
      when "true", "yes" then true
      when "false", "no" then false
      when /,/ then ENV[option].split(/\s*,\s*/)
      when /^\d+$/ then ENV[option].to_i
      else
        if option == 'only'
          [ENV[option]]
        else
          ENV[option].to_sym
        end
      end
    end
  end

  task :load_models do
    say "Loading application environment..."
    Rake::Task[:environment].invoke

    say "Zeitwerk Loading code in search of Active Record models..."
    Zeitwerk::Loader.eager_load_all

    raise "Active Record was not loaded." unless defined? ActiveRecord
  end

  task :generate => [:check_dependencies, :options, :load_models] do
    say "Generating Entity-Relationship Diagram for #{ActiveRecord::Base.descendants.length} models..."

    require "rails_erd/diagram/graphviz"
    file = RailsERD::Diagram::Graphviz.create

    say "Done! Saved diagram to #{file}."
  end
end

desc "Generate an Entity-Relationship Diagram based on your models"
task :erd => "erd:generate"
