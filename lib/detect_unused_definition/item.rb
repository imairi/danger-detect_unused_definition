#!/usr/bin/ruby
#encoding: utf-8

## cf. https://github.com/PaulTaykalo/swift-scripts/blob/master/unused.rb

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class Item
  def initialize(file, line, at)
    @file = file
    @line = line
    @at = at + 1
    if match = line.match(/(func|let|var|class|enum|struct|protocol)\s+(\w+)/)
      @type = match.captures[0]
      @name = match.captures[1]
    end
  end

  def modifiers
    return @modifiers if @modifiers
    @modifiers = []
    if match = @line.match(/(.*?)#{@type}/)
      @modifiers = match.captures[0].split(" ")
    end
    return @modifiers
  end  

  def name 
    @name
  end  

  def file
    @file
  end  

  def full_file_path
    Dir.pwd + '/' + @file
  end  

  def to_danger_output
    "#{@file}:#{@at}"
  end
end
