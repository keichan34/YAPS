defmodule Yaps.Adapters.Apns.Worker do
  use GenServer

  @timeout :infinity

  def start(args) do
    GenServer.start(__MODULE__, args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  ## GEN_SERVER LIFECYCLE ##

  def init(opts) do
    opts = default_options(opts[:env] || :prod, opts)

    {ssl_options, _} = Keyword.split(opts, [
      :cert,
      :certfile,
      :key,
      :keyfile,
      :password
    ])

    {:ok, conn} = :ssl.connect \
      to_char_list(opts[:apns_gateway]),
      opts[:apns_port],
      ssl_options,
      @timeout

    {:ok, Map.merge(new_state, %{conn: conn})}
  end

  def terminate(_reason, %{conn: conn}) do
    {_, _, pid} = conn
    if conn &&
      Process.alive?(pid) &&
      ({:ok, _} = :ssl.connection_info(conn)) do
      :ssl.close conn
    end
  end

  defp new_state do
    %{conn: nil}
  end

  defp default_options(:dev, opts) do
    Keyword.merge(opts, [
      apns_gateway:  "gateway.sandbox.push.apple.com",
      apns_port:     2195,
      feedback_host: "feedback.sandbox.push.apple.com",
      feedback_port: 2196
    ])
  end

  defp default_options(:prod, opts) do
    Keyword.merge(opts, [
      apns_gateway:  "gateway.push.apple.com",
      apns_port:     2195,
      feedback_host: "feedback.push.apple.com",
      feedback_port: 2196
    ])
  end
end
