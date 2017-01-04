Pod::Spec.new do |s|
  s.name         = "RNICloudStore"
  s.version      = "0.1.0"
  s.summary      = "AsyncStorage replacement that uses iCloud ubiquitous key store."

  s.homepage     = "https://github.com/manicakes/react-native-icloudstore"

  s.license      = "MIT"
  s.authors      = { "Mani Ghasemlou" => "mani.ghasemlou@icloud.com" }
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/manicakes/react-native-icloudstore.git" }

  s.source_files  = "*.{h,m}"

  s.dependency 'React'

end

