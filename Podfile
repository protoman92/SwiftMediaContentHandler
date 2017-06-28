# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def allPods
    pod 'SwiftUtilities/Main', :git => 'https://github.com/protoman92/SwiftUtilities.git'
    pod 'Result', '~> 3.0.0'
end

target 'SwiftMediaContentHandler' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SwiftMediaContentHandler
  allPods

  target 'SwiftMediaContentHandlerTests' do
    inherit! :search_paths
    
    # Pods for testing
    allPods
    pod 'SwiftUtilitiesTests/Main', :git => 'https://github.com/protoman92/SwiftUtilities.git'
  end
  
  target 'SwiftMediaContentHandler-Demo' do
      inherit! :search_paths
      
      # Pods for demo
      allPods
  end

end
