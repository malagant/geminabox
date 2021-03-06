class GemFactory
  def self.gem_file(*args)
    new("/tmp/geminabox-fixtures").gem(*args)
  end

  def initialize(path)
    @path = Pathname.new(File.expand_path(path))
  end

  def gem(name, options = {})
    version = options[:version] || "1.0.0"

    dependincies = options.fetch(:deps, {}).collect do |dep, requirement|
      dep = [*dep]
      gem(*dep)
      if requirement
        "s.add_dependency(#{dep.first.to_s.inspect}, #{requirement.inspect})"
      else
        "s.add_dependency(#{dep.first.to_s.inspect})"
      end
    end.join("\n")

    name = name.to_s
    path = @path.join("#{name}-#{version}.gem")
    FileUtils.mkdir_p File.dirname(path)

    unless File.exists? path 
      spec = %{
        Gem::Specification.new do |s|
          s.name              = #{name.inspect}
          s.version           = #{version.inspect}
          s.summary           = #{name.inspect}
          s.description       = s.summary + " description"
          s.author            = 'Test'
          s.files             = []
          #{dependincies}
        end
      }

      spec_file = Tempfile.open("spec") do |tmpfile|
        tmpfile << spec
        tmpfile.close

        Dir.chdir File.dirname(path) do
          system "gem build #{tmpfile.path}"
        end
      end

      raise "Failed to build gem #{name}" unless File.exists? path
    end
    path
  end

end
