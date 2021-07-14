module Pod
  class Command
    class Specctest < Command
      require 'pathname'
      require File.dirname(__FILE__)+'/buildPodBinary'
      self.summary = "BinaryBuild 命令，打包静态库并生成基础二进制podspec文件"
      self.description = "打包静态库并生成基础二进制podspec文件"
      self.command = "buildbin"
      attr_accessor :argvoption, :podName
      def initialize(argv)
          @podName = argv.shift_argument
          @argvoption = argv
      end

      self.arguments =[
          CLAide::Argument.new("PODNAME",true,false)
      ]

      def self.options
          [
            ['--git','pod组件的远程地址和--branch搭配使用'],
            ['--branch', 'pod组件的分支和--git搭配使用'],
            ['--specLocalPath','本地pod的spec文件路径，单独使用'],
            ['--version', '私有仓库的版本号，单独使用'],
            ['--source', '私有仓库资源地址，多个的话用逗号隔开'],
          ].concat(super)
       end

       def validate!
           if @podName.nil? || @podName == ""
               UI.puts "请输入组件名称，例如：BianryA"
               help!("参数错误")
           end
       end

       def run

          #实例化build对象
          sL = BuildStaticLibrary.new(@podName)
          git_op = @argvoption.option("git")
          UI.puts "--git: #{git_op}"
          if !git_op.nil?
              sL.gitAddress = git_op
          end

          branch_op = @argvoption.option("branch")
          UI.puts "--branch: #{branch_op}"
          if !branch_op.nil?
              sL.branch = branch_op
          end
          specLocalPath_op = @argvoption.option("specLocalPath")
          UI.puts "--specLocalPath: #{specLocalPath_op}"
          if !specLocalPath_op.nil?
              sL.specLocalPath = specLocalPath_op
          end

          version_op = @argvoption.option("version")
          UI.puts "--version: #{version_op}"
          if !version_op.nil?
              sL.podVersion = version_op
          end

          source_op = @argvoption.option("source")
          UI.puts "--source: #{source_op}"
          if !source_op.nil?
              sL.podSource = source_op
          end

          sL.creatClassFile
          sL.creatTestProj
          sL.creatPodFile
          sL.podinstall
       end
    end
  end
end



