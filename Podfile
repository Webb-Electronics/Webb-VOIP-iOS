# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'
source "https://gitlab.linphone.org/BC/public/podspec.git"
source "https://github.com/CocoaPods/Specs.git"

def basic_pods
	if ENV['PODFILE_PATH'].nil?
	       # pod 'linphone-sdk' , '~>5.4.82'
                #pod 'linphone-sdk'
	else
		# pod 'linphone-sdk', :path => ENV['PODFILE_PATH']  # local sdk
	end	
	pod 'SwiftLint'
end

target 'WebbVoip' do
  use_frameworks!

  basic_pods
end

target 'WebbVoipTests' do
  use_frameworks!
  basic_pods
end

target 'WebbRemoteNotificationServiceExtension' do
  use_frameworks!
  basic_pods
end
