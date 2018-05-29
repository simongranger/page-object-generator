#!/usr/bin/env ruby
require 'appium_lib'
require 'nokogiri'

def get_driver
  raise 'appium.txt file does not exist' if !File.exist?('appium.txt')
  caps = Appium.load_appium_txt file:File.join(Dir.pwd, 'appium.txt')
  Appium::Driver.new(caps, true)
end

def add_header file, filename
  file.puts("#!/usr/bin/env ruby")
  file.puts("require_relative '../../../../Test/appium/common/page_helper'")
  file.puts("class "+  File.basename(filename,File.extname(filename)).capitalize + " < Page")
end

def convert_name node_name
  node_name.tr(" ", "_").tr("-", "_").tr(":", "")
end

def populate_locators file, doc, driver
  file.puts("\n\n# Locators")
    doc.xpath('//AppiumUAT//*').each do |node|
      if node['hittable'] === 'true' || node['displayed'] === 'true'
        elements = driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          # TODO: Try finding a unique locator using attributes
          #driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          #TODO: A method should be created to replace characters
          var_name = convert_name(node['name'])
          file.puts("  #{var_name.upcase} = { name: '#{node['name']}' }")
        end
      end
    end
    file.puts("")
end

def populate_display_methods file, doc, driver
  file.puts("  # Displayed methods")
    # Going through all nodes that are displayed to make a 'displayed?' method
    doc.xpath('//AppiumUAT//*').each do |node|

      if node['displayed'] === 'true'
        elements = driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          #driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          var_name = convert_name(node['name'])
          file.puts("  def #{var_name}_displayed?")
          file.puts("    is_displayed? #{var_name.upcase}")
          file.puts("  end")
        end
      end
    end
end

def populate_click_methods file, doc, driver
  file.puts("  # Click methods")
    doc.xpath('//AppiumUAT//*').each do |node|
      
      if node['hittable'] === 'true'
        elements = driver.find_elements(name: node['name'])
        if (elements.size > 1)
          puts "Not a unique Locator"
          #driver.find_elements(name: node['name'])
        else
          puts "Unique Locator"
          var_name = convert_name(node['name'])
          file.puts("  def click_#{var_name}")
          file.puts("    click #{var_name.upcase}")
          file.puts("  end")
        end
      end
    end
    file.puts("end")
end

module Page_Object
  driver = get_driver
  driver.start_driver

  loop do 
    puts "Enter the name of the screen"
    filename = gets.chomp.downcase
    break if filename == "exit"

    doc = Nokogiri::XML(driver.driver.page_source)
    dirname = 'generated'
    FileUtils.mkdir_p(dirname) if !File.directory?(dirname)
    page_file = File.new("generated/#{filename}", "w")
    add_header(page_file, filename)

    populate_locators(page_file, doc, driver)
    populate_display_methods(page_file, doc, driver)
    populate_click_methods(page_file, doc, driver)

    page_file.close
  end
  driver.driver_quit
end