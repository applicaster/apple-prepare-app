# frozen_string_literal: true

class EnvironmentHelper
  def root_path
    (ENV['PWD']).to_s
  end

  def files_output_path
    path = "#{root_path}/Files"
    FileUtils.mkdir_p(path) unless File.directory?(path)
    path
  end
end
