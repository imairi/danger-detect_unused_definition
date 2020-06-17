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

class Unused
  def initialize 
    @results = []
    @allowPaths = []
    @denyPaths = []
  end 

  def results
    @results
  end

  def allowPaths=(paths)
    paths.each do |path|
      @allowPaths.push(path)
    end
  end

  def denyPaths=(paths)
    paths.each do |path|
      @denyPaths.push(path)
    end
  end

  def find
    puts("allow -> #{@allowPaths}")
    puts("deny -> #{@denyPaths}")
    items = []

    #rbfiles = File.join("**", "*.swift")
    #brooklyn_files = Dir.glob(rbfiles, base: "brooklyn")
    #puts("brooklyn_files: #{brooklyn_files}")
    #all_files = brooklyn_files

    if @allowPaths.length > 0
      all_files = []
      @allowPaths.each do |allowPath|
        brooklyn_files = Dir.glob("**/*.swift", base: allowPath).map{ |path|
          relativePath = File.join(allowPath, path)
          all_files.push(relativePath)
        }
      end
      puts(all_files)
    else
      all_files = Dir.glob("**/*.swift").reject do |path|
        File.directory?(path)
      end
      puts(all_files) 
    end


    puts "Start searching locally unused definitions."
    all_files.each { |my_text_file|
      file_items = grab_items(my_text_file)
      file_items = filter_items(file_items)

      non_private_items, private_items = file_items.partition { |f| !f.modifiers.include?("private") && !f.modifiers.include?("fileprivate") }
      items += non_private_items

      # Usage within the file
      if private_items.length > 0
        find_usages_in_files([my_text_file], [], private_items)
      end  

    }

    puts "Total items to be checked #{items.length}"

    items = items.uniq { |f| f.name }
    puts "Total unique items to be checked #{items.length}"

    puts "Start searching globally (it can take a while)"

    xibs = Dir.glob("**/*.xib")
    storyboards = Dir.glob("**/*.storyboard")

    find_usages_in_files(all_files, xibs + storyboards, items)
  end  

  def ignore_files_with_regexps(files, regexps)
    files.select { |f| regexps.all? { |r| Regexp.new(r).match(f.file).nil? } }
  end  

  def ignoring_regexps_from_command_line_args
    regexps = []

    arguments = ARGV.clone
    until arguments.empty?
      item = arguments.shift
      if item == "--ignore"
        regex = arguments.shift
        regexps += [regex]
      end  
    end  

    regexps += [
     "^Pods/",
     "^Carthage/",
     "fastlane/",
     "Tests.swift$",
     "Spec.swift$",
     "Tests/"
   ]

   regexps
 end  

  def find_usages_in_files(files, xibs, items_in)
    items = items_in
    usages = items.map { |f| 0 }
    files.each { |file|
      lines = File.readlines(file).map {|line| line.gsub(/^[^\/]*\/\/.*/, "")  }
      words = lines.join("\n").split(/\W+/)
      words_arrray = words.group_by { |w| w }.map { |w, ws| [w, ws.length] }.flatten

      wf = Hash[*words_arrray]

      items.each_with_index { |f, i| 
        usages[i] += (wf[f.name] || 0)
      }
      # Remove all items which has usage 2+
      indexes = usages.each_with_index.select { |u, i| u >= 2 }.map { |f, i| i }

      # reduce usage array if we found some functions already 
      indexes.reverse.each { |i| usages.delete_at(i) && items.delete_at(i) }
    }

    xibs.each { |xib|
      lines = File.readlines(xib).map {|line| line.gsub(/^\s*\/\/.*/, "")  }
      full_xml = lines.join(" ")
      classes = full_xml.scan(/(class|customClass)="([^"]+)"/).map { |cd| cd[1] }
      classes_array = classes.group_by { |w| w }.map { |w, ws| [w, ws.length] }.flatten

      wf = Hash[*classes_array]

      items.each_with_index { |f, i| 
        usages[i] += (wf[f.name] || 0)
      }
      # Remove all items which has usage 2+
      indexes = usages.each_with_index.select { |u, i| u >= 2 }.map { |f, i| i }

      # reduce usage array if we found some functions already 
      indexes.reverse.each { |i| usages.delete_at(i) && items.delete_at(i) }

    }

    regexps = ignoring_regexps_from_command_line_args()

    items = ignore_files_with_regexps(items, regexps)

    #puts items.map { |item| item.to_danger_output  }
    items.map { |item| 
      @results.push(item.to_danger_output)
    }
  end  

  def grab_items(file)
    lines = File.readlines(file).map {|line| line.gsub(/^\s*\/\/.*/, "")  }
    items = lines.each_with_index.select { |line, i| line[/(func|let|var|class|enum|struct|protocol)\s+\w+/] }.map { |line, i| Item.new(file, line, i)}
  end  

  def filter_items(items)
    items.select { |f| 
      !f.name.start_with?("test") && !f.modifiers.include?("@IBAction") && !f.modifiers.include?("override") && !f.modifiers.include?("@objc") && !f.modifiers.include?("@IBInspectable")
    }
  end

end  

