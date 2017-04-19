Pod::Spec.new do |s|

    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.name = "SwiftMediaContentHandler"
    s.summary = "Media content handler that abstracts away PHPhotoLibrary using RxSwift."
    s.requires_arc = true
    s.version = "1.0.2"
    s.license = { :type => "Apache-2.0", :file => "LICENSE.md" }
    s.author = { "Hai Pham" => "swiften.svc@gmail.com" }
    s.homepage = "https://github.com/protoman92/SwiftMediaContentHandler.git"
    s.source = { :git => "https://github.com/protoman92/SwiftMediaContentHandler.git", :tag => "#{s.version}"}
    s.framework = "Photos"
    s.framework = "UIKit"
    s.dependency 'SDWebImage/WebP'
    s.dependency 'SwiftUtilities/Main'

    s.subspec 'Main' do |main|
        main.source_files = "SwiftMediaContentHandler/**/*.{swift}"
    end

end
