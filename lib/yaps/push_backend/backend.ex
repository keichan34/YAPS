defmodule Yaps.PushBackend.Backend do
  @moduledoc false

  def send_push(backend, adapter, recipient, payload, opts) do
    adapter.send_push(backend, recipient, payload, opts)
  end
end
