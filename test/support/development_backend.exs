defmodule Yaps.DevelopmentBackened do
  use Yaps.PushBackend, adapter: Yaps.Adapters.Apns

  def conf do
    [env: :dev,
     certfile: "./test_data/certificate.pem",
     keyfile: "./test_data/key.pem"]
  end
end
