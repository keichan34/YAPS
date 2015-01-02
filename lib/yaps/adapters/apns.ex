defmodule Yaps.Adapters.Apns do
  @moduledoc """
  This is the adapter module for the Apple Push Notification Service.
  """

  @behaviour Yaps.Adapter

  alias Yaps.Adapters.Apns.Worker

  # Adapter API

  @doc false
  defmacro __using__(_opts) do
    quote do
      def __apns__(:pool_name) do
        __MODULE__.Pool
      end
    end
  end

  @doc false
  def start_link(backend, opts) do
    {pool_opts, worker_opts} = prepare_start(backend, opts)
    :poolboy.start_link(pool_opts, worker_opts)
  end

  @doc false
  def stop(backend) do
    pool = backend_pool(backend)
    :poolboy.stop(pool)
  end

  @doc false
  def send_push(backend, recipient, payload, opts \\ []) do
    pool = backend_pool(backend)
    use_worker(pool, :infinity, fn worker ->
      Worker.send_push(worker, recipient, payload, opts)
    end)
  end

  defp backend_pool(backend) do
    pid = backend.__apns__(:pool_name) |> Process.whereis

    if is_nil(pid) or not Process.alive?(pid) do
      raise ArgumentError, message: "backend #{inspect backend} is not started"
    end

    pid
  end

  defp prepare_start(backend, opts) do
    pool_name = backend.__apns__(:pool_name)
    {pool_opts, worker_opts} = Dict.split(opts, [:size, :max_overflow])

    pool_opts = pool_opts
      |> Keyword.update(:size, 5, &String.to_integer(&1))
      |> Keyword.update(:max_overflow, 10, &String.to_integer(&1))

    pool_opts = [
      name: {:local, pool_name},
      worker_module: Worker ] ++ pool_opts

    {pool_opts, worker_opts}
  end

  defp use_worker(pool, timeout, fun) do
    worker = :poolboy.checkout(pool, true, timeout)

    try do
      fun.(worker)
    after
      :poolboy.checkin(pool, worker)
    end
  end
end
