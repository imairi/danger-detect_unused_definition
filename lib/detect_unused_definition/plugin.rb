#!/usr/bin/ruby
#encoding: utf-8

require_relative "./unused"

module Danger
  class DangerDetectUnusedDefinition < Plugin

    attr_accessor :allow_paths

    def detect(text)
      unused = Unused.new
      unused.allowPaths = allow_paths
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
