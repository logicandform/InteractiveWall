use_frameworks!
workspace 'MapExplorer'

abstract_target 'All' do
    pod 'MONode', :git => 'git@github.com:SlantDesign/mo.git'
    pod 'Alamofire', '~> 4.5'

    target 'MapExplorer-iOS' do
        project 'MapExplorer-iOS/MapExplorer-iOS.xcodeproj'
        platform :ios, '9.3'

        pod 'C4', '~> 3.0.1'
    end

    target 'MapExplorer-tvOS' do
        project 'MapExplorer-tvOS/MapExplorer-tvOS.xcodeproj'
        platform :tvos, '11.2'
    end

    target 'MapExplorer-macOS' do
        project 'MapExplorer-macOS/MapExplorer-macOS.xcodeproj'
        platform :osx, '10.13'
    end

end
