use_frameworks!
inhibit_all_warnings!
workspace 'InteractiveWall'

abstract_target 'All' do
    pod 'MONode', :git => 'git@github.com:SlantDesign/mo.git'
    pod 'Alamofire', '~> 4.7'
    pod 'PromiseKit', '~> 4.4'
    pod 'PromiseKit/Alamofire'
    pod 'AlamofireImage'
    pod 'MacGestures'

    target 'MapExplorer' do
        project 'MapExplorer/MapExplorer.xcodeproj'
        platform :osx, '10.14'
    end

    target 'WindowExplorer' do
        project 'WindowExplorer/WindowExplorer.xcodeproj'
        platform :osx, '10.14'

        pod 'ReachabilitySwift'
    end

    target 'NodeExplorer' do
        project 'NodeExplorer/NodeExplorer.xcodeproj'
        platform :osx, '10.14'
    end
end
