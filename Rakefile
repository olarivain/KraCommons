require 'rubygems'
require 'xcodebuilder'

x86Builder = XcodeBuilder::XcodeBuilder.new do |config|
  # basic workspace config
  config.build_dir = :derived
  config.workspace_file_path = "KraCommons.xcworkspace"
  config.scheme = "KraCommonsx86"
  config.configuration = "Release" 
  config.sdk = "macosx"
  config.skip_clean = false
  config.verbose = false

end

armBuilder = XcodeBuilder::XcodeBuilder.new do |config|
  # basic workspace config
  config.build_dir = :derived
  config.workspace_file_path = "KraCommons.xcworkspace"
  config.scheme = "KraCommonsARM"
  config.configuration = "Release" 
  config.sdk = "iphoneos"
  config.info_plist = "./Resources/Info.plist"
  config.skip_dsym = true
  config.skip_clean = false
  config.verbose = false
  config.increment_plist_version = true
  config.tag_vcs = true
  config.pod_repo = "kra"
  config.podspec_file = "KraCommons.podspec"
  
  # tag and release with git
  config.release_using(:git) do |git|
    git.branch = "master"
  end
end

task :clean do
	# dump temp build folder
	FileUtils.rm_rf "./build"
	FileUtils.rm_rf "./pkg"

	# and cocoa pods artifacts
	FileUtils.rm_rf x86Builder.configuration.workspace_file_path
	FileUtils.rm_rf "Podfile.lock"
end

# pod requires a full clean and runs pod install
task :pod => :clean do
	system "pod install"
end

task :release => :pod do
	x86Builder.build
	armBuilder.pod_release
end