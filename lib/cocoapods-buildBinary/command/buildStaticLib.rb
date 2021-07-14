#!/usr/bin/ruby

class BuildLibrary
    attr_accessor :targetName, :universal_output_folder, :build_dir
    def initialize(argv)
        @targetName = argv
        @universal_output_folder = "../BuildProducts/#{@targetName}"
        # 编译输出的路径
        @build_dir = 'build'
        puts "universal_output_folder: #{@universal_output_folder}"
        system "rm -rf '#{@universal_output_folder}'"
        system "mkdir -p '#{@universal_output_folder}'"
        system "rm -rf '#{@build_dir}'"

    end

    def build(configuration)
        _targetName = @targetName
        _UNIVERSAL_OUTPUT_FOLDER=@universal_output_folder
        _BUILD_DIR=@build_dir
        _PODS_PROJECT="Pods/Pods.xcodeproj"
        `xcodebuild -project '#{_PODS_PROJECT}' -target '#{_targetName}' ONLY_ACTIVE_ARCH=NO -configuration #{configuration} -sdk iphoneos  BUILD_DIR='../#{_BUILD_DIR}'`
        `mkdir -p '#{_UNIVERSAL_OUTPUT_FOLDER}/#{configuration}'`

        _OS_TARGET_PATH="#{_BUILD_DIR}/#{configuration}-iphoneos/#{_targetName}"

        `cp -r '#{_OS_TARGET_PATH}/lib#{_targetName}.a' '#{_UNIVERSAL_OUTPUT_FOLDER}/#{configuration}'`
        # 2、复制头文件到目标文件夹，把pod工程中的公开头文件拷贝出来
        _HEADER_FOLDER="Pods/Headers/Public/#{_targetName}"
        `cp -r '#{_HEADER_FOLDER}' '#{_UNIVERSAL_OUTPUT_FOLDER}/#{configuration}/include'`

        # 3、拷贝bundle文件，如果存在bundle文件可以用以下拷贝bundle
        _BUNDLE_PATH=`$(find '#{_OS_TARGET_PATH}' -name '*.bundle')`
        if !_BUNDLE_PATH.nil?
            `cp -r #{_BUNDLE_PATH} '#{_UNIVERSAL_OUTPUT_FOLDER}/#{configuration}'`
        end
    end

    def startbuild
        build("Debug")
        build("Release")
        `open #{@universal_output_folder}`
    end
end










