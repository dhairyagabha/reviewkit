tailwind_input = "app/assets/tailwind/changeset/application.css"
tailwind_output = "app/assets/builds/changeset/application.css"

namespace :changeset do
  desc "Build the engine's shipped TailwindCSS asset"
  task :build_css do
    sh "bundle exec tailwindcss -i #{tailwind_input} -o #{tailwind_output} --minify"
  end

  desc "Build the engine's shipped frontend assets"
  task build_assets: :build_css
end
