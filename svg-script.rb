require 'rest-client'
require 'mini_magick'
require 'fileutils'
require 'xcodeproj'

url_to_filename = {
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/caution.svg' => 'caution.pdf',
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/compass.svg' => 'check.pdf',
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/ch.svg' => 'circles.pdf',
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/cartman.svg' => 'cartman.pdf',
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/dukechain.svg' => 'duke.pdf',
  'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/eff.svg' => 'eff.pdf'
}

base_xcode_path = "/Users/pietroballarin/Desktop/SvgTest/SvgTest"
xcode_project_path = "/Users/pietroballarin/Desktop/SvgTest/SvgTest.xcodeproj"

project = Xcodeproj::Project.open(xcode_project_path)
target = project.targets.first

url_to_filename.each do |url, filename_with_extension|
  # Extract the filename without extension
  filename = File.basename(filename_with_extension, ".*")

  svg_content = RestClient.get(url)

  image = MiniMagick::Image.read(svg_content) do |config|
    config.format 'svg'
  end

  image.format 'pdf'

  # Calculate the absolute paths for new and existing files
  imageset_folder = "#{base_xcode_path}/Assets.xcassets/#{filename}.imageset"
  FileUtils.mkdir_p(imageset_folder)

  # Corrected paths for images
  png_output_path = "#{imageset_folder}/#{filename_with_extension}"

  # Write the PNG image to the new output path
  image.write png_output_path

  puts "Conversion complete: #{png_output_path}"

  # Add the image to the Xcode project
  image_asset = project.new_file(png_output_path)

  # Add the file reference to the resources build phase
  build_file = target.resources_build_phase.add_file_reference(image_asset)

  # Create the Contents.json file for the image set
  contents_json_path = "#{imageset_folder}/Contents.json"
  File.open(contents_json_path, 'w') do |file|
    file.write(JSON.pretty_generate({
      "images" => [
        {
          "filename" => filename_with_extension,
          "idiom" => "universal"
        }
      ],
      "info" => {
        "version" => 1,
        "author" => "xcode"
      }
    }))
  end
end

# Save the modified project
project.save
