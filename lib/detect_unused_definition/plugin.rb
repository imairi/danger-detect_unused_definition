#!/usr/bin/ruby
#encoding: utf-8

require_relative "./unused"

module Danger
  class DangerDetectUnusedDefinition < Plugin

    # set target directory paths.
    # ex) ["SampleApp", "SampleAppTests"] 
    attr_accessor :allow_paths

    # remove particular paths from Danger results. enable to use Regexp.
    # ex) ["*Model.swift", "SampleAppTests/Stub/*"]
    attr_accessor :deny_paths

    def detect
      unused = Unused.new
      unused.allow_paths = allow_paths.nil? ? [] : allow_paths
      unused.deny_paths = deny_paths.nil? ? [] : deny_paths
      unused.find
      unused.results.each do |result|
        unused = result.split(":")
        filepath = unused[0]
        line = unused[1].to_i
        if line > 0 then
          warn("unused definition!", file: filepath, line: line)
        end
      end
    end 
    
  end
end
