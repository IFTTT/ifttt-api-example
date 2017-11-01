require "./app"

map "/mobile_api" do
  run MobileAPIController
end

map "/ifttt/v1" do
  run IFTTTProtocolController
end

map "/" do
  run WebUIController
end
