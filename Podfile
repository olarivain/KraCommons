require 'FileUtils'

# attempt to load custom paths for our libraries
custom_path = "./DevPaths.rb"
if File.exists? custom_path then
	custom_paths = eval(File.new(custom_path).read)
	puts "Using custom paths for OpenTable libraries from #{custom_path}."
else 
	custom_paths = Hash.new
	puts "Released version of OpenTable libraries will be used. If you wish to use local version, create DevPaths.rb, see DevPaths-sample.rb for an example"

end
puts

platform :osx, "10.7"

pod "AFNetworking", "~> 1.1.0"
pod "CocoaLumberjack", "~> 1.6"

target :KraCommonsx86 do
	platform :osx, "10.7"
end

target :KraCommonsarm do
	platform :ios, "5.0"
end

puts