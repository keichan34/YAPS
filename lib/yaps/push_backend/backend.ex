defmodule Yaps.PushBackend.Backend do
  @moduledoc false

  def start_link(backend, adapter) do
    adapter.start_link(backend, backend.conf)
  end

  def stop(backend, adapter) do
    adapter.stop(backend)
  end
end
