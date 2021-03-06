#!/usr/bin/ruby
#encoding: utf-8

## cf. https://github.com/PaulTaykalo/swift-scripts/blob/master/unused.rb

require_relative "./item"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class Unused
  def initialize 
    @results = []
    @allow_paths = []
    @deny_paths = []
  end 

  def results
    @results
  end

  def allow_paths=(paths)
    paths.each do |path|
      @allow_paths.push(path)
    end
  end

  def deny_paths=(paths)
    paths.each do |path|
      @deny_paths.push(path)
    end
  end

  def find
    puts("allow -> #{@allow_paths}")
    puts("deny -> #{@deny_paths}")
    items = []

    if @allow_paths.length > 0
      all_files = []
      @allow_paths.each do |allow_path|
        brooklyn_files = Dir.glob("**/*.swift", base: allow_path).map{ |path|
          relative_path = File.join(allow_path, path)
          all_files.push(relative_path)
        }
      end
    else
      all_files = Dir.glob("**/*.swift").reject do |path|
        File.directory?(path)
      end
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
    regexps += @deny_paths

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

