require 'rubygems'
require 'ot-ios-builder'

workspace_path = "KraCommons.xcworkspace"

task :clean do
	# dump temp build folder
	FileUtils.rm_rf "./build"
	FileUtils.rm_rf "./pkg"

	# and cocoa pods artifacts
	FileUtils.rm_rf workspace_path
	FileUtils.rm_rf "Podfile.lock"
end

# pod requires a full clean and runs pod install
task :pod => :clean do
	system "pod install"
end

BetaBuilder::Tasks.new do |config|	
	# basic workspace config
	config.build_dir = :derived
	config.workspace_path = workspace_path
	config.scheme         = "KraCommonsx86"
	config.configuration = "Release" 
	config.app_info_plist = "./Resources/Info.plist"

	config.pod_repo = "kra"
	config.spec_file = "KraCommons.podspec"
	config.skip_clean = false
	config.verbose = false
	config.sdk = "macosx"


	config.skip_version_increment = false
	config.skip_scm_tagging = false

	# tag and release with git
	config.release_using(:git) do |git|
	end
end