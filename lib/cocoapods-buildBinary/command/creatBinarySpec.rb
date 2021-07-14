#!/usr/bin/ruby
require 'date'
require 'tempfile'
require 'fileutils'

#关于json序列化
#执行：gem install json
require 'rubygems'
require 'json'

#❯ ruby creatBinarySpec.rb PYCommunity 1
# 参数 podname  是否覆盖原有的spec 1覆盖，不传或者传0不覆盖


class CreateBinarySpec

    attr_reader :podName, :podRepoPath, :tempTime, :binarySpecPath, :jsonSpecObj, :replaceOld
    def initialize(podname)
        if ARGV[1]
            @replaceOld = ARGV[1]
        else
            @replaceOld = "0"
        end
        
        if !podname.nil? or podname.length > 3
            @podName = podname
            @podRepoPath = nil
            @tempTime = nil
            @binarySpecPath = Dir.pwd
            puts "binarySpecPath: #{@binarySpecPath}"
            # 新建一个文件夹
            # if !File.directory?("#{podname}")
            #     FileUtils.mkdir("#{podname}")
            # end
            
            @jsonSpecObj = nil
        else
            puts "参数为空，直接退出"
            exit
        end
    end

    #寻找可用的spec文件
    def searchPodspec
        if File.file?("#{@binarySpecPath}/#{@podName}/#{@podName}.podspec") and @replaceOld == '0'
            puts "#{podName}库 podspec 已存在"
        else
            先从localPodspecs寻找
            specPath = searchPodsProjectLocalspec
            if !specPath.nil?
                #local 创建spec
                createBianrySpecFile(specPath)
            else
                #从pod仓库中寻找
                specPath = searchPodRepoSpec
                if !specPath.empty?
                    createBianrySpecFile(specPath)
                else
                    puts "没有找到 #{@podName} 的spec文件"
                    exit
                end
            end
        end
        
    end

    #从本地Pod工程Local Podspecs文件夹寻找sepc.json
    def searchPodsProjectLocalspec
        _localSpecPath = "../Driver_4.6/Pods/Local\ Podspecs/#{@podName}.podspec.json"
        if File.file?(_localSpecPath)
            return _localSpecPath
        else
            return nil
        end
    end

    #从pod仓库中寻找sepc
    def searchPodRepoSpec
        #用户路径
        _userPath = "/Users"
        recursionSearchCocoapodsFolder(_userPath)
        @podRepoPath = "#{@podRepoPath}/repos/58corp-com.wuba.jxedt.ios-jxedtspecs/#{podName}"
        if !File.directory?(@podRepoPath)
           return @podRepoPath
        end
        Dir.chdir(@podRepoPath)
        if File.directory? @podRepoPath
            tempPath = @podRepoPath.dup
            Dir.glob("*").each do |aaa|
                pathSpec = "#{@podRepoPath}/#{aaa}/#{podName}.podspec"
                #通过文件创建时间来找到最新的podspec文件
                time = File.ctime(pathSpec)
                # puts "time: #{time}"
                if @tempTime.nil?
                    @tempTime = time
                    tempPath = pathSpec
                else
                    if @tempTime <= time
                       @tempTime = time
                       # puts pathSpec
                       tempPath = pathSpec
                    end
                end
            end
            @podRepoPath = tempPath
        end

        puts  "pod Repo 根据创建时间搜索到最新的podspec:\n  #{@podRepoPath}"
        return @podRepoPath
    end

    #寻找tag值最大的文件夹

    #序列化json字符串
    def serializeSpecJson(path)
        json = File.read(path)
        @jsonSpecObj = JSON.parse(json)
        # puts "json对象：#{@jsonSpecObj}"
        return @jsonSpecObj
    end

    #递归寻找 .cocoapods 文件夹，只在Users下的用户目录寻找，只找1层
    def recursionSearchCocoapodsFolder(path)
        if File.directory? path
            Dir.foreach(path) do |file|
                if file != ".cocoapods"
                    if !file.include?(".") and !file.include?("..") and !file.include?("Shared") and !file.include?("Guest")
                        # puts "file: #{file}"
                        arr = path.split("\/")
                        # puts "arr: #{arr}"
                        if arr.length < 3
                            path1 = path + "/#{file}"
                            recursionSearchCocoapodsFolder(path1)
                        end
                    end
                else
                    # puts path + "/#{file}"
                    @podRepoPath = path + "/#{file}"
                end
            end
        end
    end

    #创建二进制spec文件并将文件移动到目的文件夹
    def createBianrySpecFile(filePath)
        if filePath.include?(".json")
            #开始序列化
            obj = serializeSpecJson(filePath)
            binarySpecFromJson(obj)
        else
            binarySpecFromSpec
        end
    end

    #从localPod加载
    def binarySpecFromJson(jsonObj)
        arr = ["prefix_header_file","public_header_files",
            "platforms","ios","tvos","osx","private_header_files","exclude_files",
            "preserve_paths","requires_arc"]
        hasResources = 0
        hasVendored_libraries = 0
        temp_file = Tempfile.new("#{podName}.spec")
        temp_file.puts "Pod::Spec.new do |s|"
        jsonObj.each do |key,value|
            if key == "subspecs"
                puts "#{podName}库中含有Subspec，暂时不支持"
                # Dir.delete("#{@binarySpecPath}/#{podName}")
                
            elsif key == "source_files"
                temp_file.puts " s.source_files = 'Debug/include/*.{h}' "
            elsif key == "vendored_libraries"
                hasVendored_libraries = 1
                if value.class == String
                    temp_file.puts " s.vendored_libraries = 'Debug/*.a' "
                elsif value.class == Array
                    newValue = ""
                    value.each do |value1|
                        newValue += "#{value1},"
                    end
                    newValue += "Debug/*.a"
                    temp_file.puts " s.vendored_libraries = #{newValue} "
                end
            elsif key == "resources"
                hasResources = 1
                temp_file.puts " s.resources = 'Debug/*.bundle' "
            elsif key == "license"
                temp_file.puts " s.license = { :type => 'MIT', :file => 'LICENSE' } "
            elsif key == "authors"
                if value.class == Hash
                    value.each do |hkey,hvalue|
                        temp_file.puts " s.author = { '#{hkey}' => '#{hvalue}' } "
                    end
                end
            elsif key == "libraries" || key == "frameworks" || key == "vendored_frameworks" || key == "weak_frameworks" || key == "compiler_flags" || key == "prefix_header_contents"
                if value.class == String
                    temp_file.puts " s.#{key} = '#{value}' "
                elsif value.class == Array
                    newValue = ""
                    index = -1
                    value.each do |value1|
                        index += 1
                        k = index + 1
                        if k == value.length
                            newValue += "'#{value1}'"
                        else
                            newValue += "'#{value1}',"
                        end
                    end
                    temp_file.puts " s.#{key} = #{newValue} "
                end
            elsif arr.include?(key)
                puts "#{key} 不用写入到文件中"
            elsif key == "dependencies"
                value.each do |dkey,dvalue|
                    if dvalue.length > 0
                        dvalue1 = dvalue[0]
                        temp_file.puts " s.dependency '#{dkey}', '#{dvalue1}'"
                    else
                        temp_file.puts " s.dependency '#{dkey}' "
                    end
                end
            elsif key == "source"
                sarr = []
                value.each do |skey,svalue|
                    sarr << svalue
                end
                newValue = " s.source = { :git=> '#{sarr[0]}',:tag=> '#{sarr[1]}'}"
                temp_file.puts newValue
            else
                if value.class == Array
                    newValue = ""
                    index = -1
                    value.each do |value1|
                        index += 1
                        k = index + 1
                        if k == value.length
                            newValue += "'#{value1}'"
                        else
                            newValue += "'#{value1}',"
                        end
                    end
                    temp_file.puts " s.frameworks = #{newValue} "
                elsif value.class == Hash
                    value.each do |fkey,fvalue|
                        if fvalue.class == String
                            temp_file.puts " s.#{key} = {'#{fkey}' => '#{fvalue}'}"
                        end
                    end
                else
                    temp_file.puts " s.#{key} = '#{value}'"
                end
                
                puts "key= #{key}; value= #{value}"
            end
        end

        temp_file.puts " s.ios.deployment_target = '9.0'"

        if hasResources == 0
            temp_file.puts " s.resources = 'Debug/*.bundle'"
        end
        if hasVendored_libraries == 0
            temp_file.puts " s.vendored_libraries = 'Debug/*.a'"
        end

        temp_file.puts "end"

        temp_file.close
        FileUtils.mv(temp_file.path, "#{@binarySpecPath}/BuildProducts/#{podName}/#{podName}.podspec")
        temp_file.close
        temp_file.unlink

        system "open #{@binarySpecPath}/BuildProducts/#{podName}/#{podName}.podspec"

    end


    #从pod repo 仓库中组装 binarySpec
    def binarySpecFromSpec
        temp_file = Tempfile.new("#{podName}.spec")
        File.open("#{@podRepoPath}","r+") do |file|
            exculdeArr = ["prefix_header_file","public_header_files","private_header_files","exclude_files","preserve_paths"]
            hasVendored_libraries = 0
            hasResources = 0
            tS = ""
            file.each do |line|
                if line.include?("source_files") and !line.include?("#")
                    arr = line.split("source_files")
                    tS = arr[0]
                    newLine = arr[0]+"source_files ='Debug/include/*.{h}'"
                    temp_file.puts newLine
                elsif line.include?("resources") and !line.include?("#")
                    hasResources = 1
                    arr = line.split("resources")
                    newLine = arr[0]+"resources ='Debug/*.bundle'"
                    temp_file.puts newLine
                elsif line.include?("vendored_libraries") and !line.include?("#")
                    hasVendored_libraries  = 1
                    newLine = line + ",'Debug/*.a'"
                    temp_file.puts newLine
                elsif line.include?("end") and !line.include?(".") and !line.include?("#")
                    puts "最后end行：#{line}"
                elsif line.include?(".subspec") and !line.include?("#")
                    puts "#{podName}库中含有Subspec，暂时不支持"
                    # Dir.delete("#{@binarySpecPath}/#{podName}")
                    # exit
                elsif line.include?("resource_bundles")
                    puts "\n ****请您手动删除最终binary spec中的 resource_bundles 相关内容***** \n1"
                else
                    whiteKey = 0
                    exculdeArr.each do |value1|
                        if line.include?(value1)
                            whiteKey = 1
                            puts "\n $$$$$ #{line} 中包含 #{value1}，所以不写入 $$$$$ \n 2"
                            break
                        end
                    end
                    if whiteKey == 0
                        temp_file.puts line
                    end
                end
            end
            if hasVendored_libraries == 0
                newLine = tS+"vendored_libraries = 'Debug/*.a'"
                temp_file.puts newLine
            end
            if hasResources == 0
                newLine = tS+"resources = 'Debug/*.bundle'"
                temp_file.puts newLine
            end

            temp_file.puts "end"
        end

        temp_file.close
        FileUtils.mv(temp_file.path, "#{@binarySpecPath}/BuildProducts/#{podName}/#{podName}.podspec")
        temp_file.close
        temp_file.unlink

        system "open #{@binarySpecPath}/BuildProducts/#{podName}/#{podName}.podspec"
    end

end


















