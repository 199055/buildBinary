#!/usr/bin/ruby

require 'xcodeproj'
require 'tempfile'
require 'fileutils'


#支持单独打单个的静态库并自动成生成相应的spec文件

#ruby buildPodBinary.rb podname igit branch （分支）
#ruby buildPodBinary.rb podname specpath （本地pod）
#ruby buildPodBinary.rb podname （私有库）
#ruby buildPodBinary.rb podname  1.0.0 （私有库）


class BuildStaticLibrary
    attr_accessor :oldPath, :podName, :specPath, :gitAddress, :branch, :podVersion, :podSource
    
    #specPath 和 podName 必须匹配，否则会失败
    def initialize(podName)
        if  podName.nil? || podName == ""
            puts "podName 不能为空"
            exit
        end
        @podName = podName
        @oldPath = Dir.pwd

    end
    
    #创建main.m文件，用于编译程序入口
    def creatClassFile
        if !File.exist?("./App")
             FileUtils.mkdir_p("App/App")
        end
        tem_file1 = Tempfile.new("main.m")
        tem_file1.puts '@import Foundation;'
        tem_file1.puts '@import UIKit;'
        tem_file1.puts 'int main() {}'
        tem_file1.close
        FileUtils.mv(tem_file1.path, './App/App/main.m')
        tem_file1.close
        tem_file1.unlink
    end

    #创建xcodeProj，用于编译
    def creatTestProj
        #进入下级目录
        # system "cd App"
        Dir.chdir('./App')
        proj = Xcodeproj::Project.new(".",false)

        app_target = proj.new_target(:framework, 'App', :ios, '9.0')
        implm_ref = proj.main_group.new_reference('./App/main.m')

        app_target.add_file_references([implm_ref])

        proj.save('App.xcodeproj')

    end

    #创建podfile文件，用于install相关pod
    def creatPodFile
        tem_file = Tempfile.new("Podfile")
        tem_file.puts "source 'https://github.com/CocoaPods/Specs.git'"
        if !@podSource.nil?
            sourceArr = @podSource.split(',')
            sourceArr.each do |value|
                tem_file.puts "source '#{value}'"
            end
        end
        tem_file.puts "platform :ios, '9.0'"
        tem_file.puts "# 忽略引入库的所有警告"
        tem_file.puts "inhibit_all_warnings!"
        tem_file.puts "target 'App' do"
        if !@branch.nil?
            tem_file.puts "    pod '#{@podName}', :git=>'#{@gitAddress}', :branch=> '#{@branch}'"
        elsif !@specPath.nil?
            tem_file.puts "    pod '#{@podName}', :path=>'#{@specPath}'"
        elsif !@podVersion.nil?
            tem_file.puts "    pod '#{@podName}', '~> #{podVersion}' "
        else
            tem_file.puts "    pod '#{@podName}'"
        end
        
        tem_file.puts "end"

        tem_file.close
        FileUtils.mv(tem_file.path, './Podfile')
        tem_file.close
        tem_file.unlink
    end

    def podinstall
        system "pod install --repo-update"
        require File.dirname(__FILE__)+'/buildStaticLib'
        sleep(1)
        build = BuildLibrary.new(@podName)
        build.startbuild
        sleep(1)
        Dir.chdir(@oldPath)
        path = "./App/Pods/Local\ Podspecs/#{@podName}.podspec.json"
        
        creatBinarySpec(path)

        FileUtils.rm_r("#{@oldPath}/App")
        # FileUtils.rm_r("#{@oldPath}/BuildProducts")
        # FileUtils.rm_r("#{@oldPath}/Buildbin")
        puts "最终文件路径： #{@oldPath}/BuildProducts"
    end

    def creatBinarySpec(specJsonPath)
        require File.dirname(__FILE__)+'/creatBinarySpec'
        binary = CreateBinarySpec.new(@podName)
        if File.file?(specJsonPath)
            binary.createBianrySpecFile(specJsonPath)
        else
            _path = binary.searchPodRepoSpec
            puts "仓库地址：#{_path}"
            if !_path.nil? and File.file?(_path)
                binary.createBianrySpecFile(_path)
            else
                puts "两种可能：\n1、#{podName} 是三方库，暂时不支持生成静态库的spec文件，请手动添加\n2、#{podName} 没有被发布到私有库"
            end
        end
        
    end
    
    
end














