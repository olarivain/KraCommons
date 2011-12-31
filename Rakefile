require 'XCodeDeployer'
require 'XCodeProduct'

name = "KraCommons"
products = [ XCodeProduct.new(name, "#{name}-iPhone", "Release", ["iphoneos", "iphonesimulator"]),
			XCodeProduct.new(name, "#{name}-x86", "Release", ["macosx"])]
builder = XCodeDeployer.new(products, true)

task :setup do
	builder.setup
end

task :default => [:build, :deploy] do
end

task :clean do
	puts "cleaning " + name
	builder.clean
end

task :build do
	puts "building " + name
	builder.build
end

task :deploy do
	puts "Deploying " + name
	builder.deploy
end

task :release => [:setup, :clean, :build, :deploy] do
	builder.release
end

