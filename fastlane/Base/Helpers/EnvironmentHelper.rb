# frozen_string_literal: true

class EnvironmentHelper
  def root_path
    (ENV['PWD']).to_s
  end

  def files_output_path
    "#{root_path}/Files"
  end
end
