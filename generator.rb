#!/usr/bin/env ruby
require 'appium_lib'
require 'nokogiri'




caps = Appium.load_appium_txt file:File.join(Dir.pwd, 'appium.txt') 
@driver = Appium::Driver.new(caps, true)
@driver.start_driver



  loop do 

    puts "Enter FileName"
    filename = gets.chomp
    break if filename === "exit"
    puts "FileName: " + filename

    doc = Nokogiri::XML(@driver.driver.page_source)

    #Creating file
    dirname = 'generated'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    out_file = File.new("generated/" + filename, "w")

    #Header
    out_file.puts("#!/usr/bin/env ruby")
    out_file.puts("require_relative '../../../../Test/appium/common/page_helper'")
    out_file.puts("class "+  File.basename(filename,File.extname(filename)).capitalize + " < Page")
    out_file.puts("")
    
    # TODO: A method should be created to avoid code repeat
    # Going through all nodes that are hittable or displayed
    out_file.puts("  # Locators")
    doc.xpath('//AppiumUAT//*').each do |node|
      if node['hittable'] === 'true' || node['displayed'] === 'true'
        elements = @driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          # TODO: Try finding a unique locator using attributes
          #@driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          #TODO: A method should be created to replace characters
          out_file.puts("  " + node['name'].upcase.tr(" ", "_").tr("-", "_").tr(":", "") + " = { name: '" + node['name'] + "' }")
        end
      end
    end
    out_file.puts("")

    out_file.puts("  # Displayed methods")
    # Going through all nodes that are displayed to make a 'displayed?' method
    doc.xpath('//AppiumUAT//*').each do |node|

      if node['displayed'] === 'true'
        elements = @driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          #@driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          out_file.puts("  def " + node['name'].tr(" ", "_").tr("-", "_").tr(":", "") + "_displayed?")
          out_file.puts("    is_displayed? " + node['name'].upcase.tr(" ", "_").tr("-", "_").tr(":", "") + "")
          out_file.puts("  end")
        end
      end
    end
    
    out_file.puts("")
    
    # Going through all nodes that are hittable to make a 'click' method
    out_file.puts("  # Click methods")
    doc.xpath('//AppiumUAT//*').each do |node|
      
      if node['hittable'] === 'true'
        elements = @driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          #@driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          out_file.puts("  def click_" + node['name'].tr(" ", "_").tr("-", "_").tr(":", ""))
          out_file.puts("    click " + node['name'].upcase.tr(" ", "_").tr("-", "_").tr(":", "") + "")
          out_file.puts("  end")
        end
      end
    end
    out_file.puts("end")
    out_file.close
  end




@driver.driver_quit
