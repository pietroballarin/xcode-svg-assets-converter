require 'rest-client'
require 'mini_magick'
require 'fileutils'
require 'json'

base_xcode_path = "/Users/pietroballarin/Desktop/SvgTest/SvgTest"
xcode_project_path = "/Users/pietroballarin/Desktop/SvgTest/SvgTest.xcodeproj"

# Read URLs and filenames from the JSON file
json_data = File.read('/Users/pietroballarin/Desktop/xcode-svg-assets-converter/Assets.json')
url_and_filename_data = JSON.parse(json_data)

url_and_filename_data.each do |entry|
  url = entry['url']
  filename_without_extension = entry['filename'] # Filename without extension

  svg_content = RestClient.get(url)

  image = MiniMagick::Image.read(svg_content) do |config|
    config.format 'svg'
  end

  image.format 'pdf'

  # Calculate the absolute paths for new and existing files
  imageset_folder = "#{base_xcode_path}/Assets.xcassets/#{filename_without_extension}.imageset"
  FileUtils.mkdir_p(imageset_folder)

  # Corrected paths for images
  pdf_output_filename = "#{filename_without_extension}.pdf"
  pdf_output_path = "#{imageset_folder}/#{pdf_output_filename}"

  # Write the PDF image to the new output path
  image.write pdf_output_path

  puts "Conversion complete: #{pdf_output_path}"

  # Create the Contents.json file for the image set
  contents_json_path = "#{imageset_folder}/Contents.json"
  File.open(contents_json_path, 'w') do |file|
    file.write(JSON.pretty_generate({
      "images" => [
        {
          "filename" => pdf_output_filename, # Use the PDF filename here
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
