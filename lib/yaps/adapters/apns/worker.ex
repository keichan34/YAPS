defmodule Yaps.Adapters.Apns.Worker do
  use GenServer

  alias Yaps.Adapters.Apns.DataTransformers

  @timeout :infinity

  def start(args) do
    GenServer.start(__MODULE__, args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def send_push(worker, recipient, payload, opts \\ []) do
    GenServer.call(worker, {:send_push, recipient, payload, opts})
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

  def handle_info({:ssl, _socket, raw_data}, s) do
    # TODO: The only reason we'll get data from the socket is if there's an error
    # with the last packet. In that case, we'll have to store what messages haven't
    # been delivered yet, then we can stop our process.
    IO.puts inspect(raw_data)
    {:noreply, s}
  end

  def handle_info({:ssl_closed, _socket}, s) do
    {:stop, :ssl_closed, s}
  end

  def handle_call({:send_push, recipient, payload, opts}, _from, %{conn: conn} = s) do
    ident = :crypto.rand_bytes(4)
    opts = opts |>
      Keyword.put(:identifier, ident)

    data = DataTransformers.encode(recipient, payload, opts)
    case :ssl.send(conn, data) do
      {:error, reason} ->
        raise "SSL Error: #{inspect reason}"
      :ok ->
    end

    s = update_in(s.sent_notifications,
      &HashDict.put(&1, ident, {recipient, payload, opts}))

    {:reply, :ok, s}
  end

  def terminate(_reason, %{conn: conn}) do
    {_, _, pid} = conn
    if conn && Process.alive?(pid) do
      case :ssl.connection_info(conn) do
        {:ok, _} ->
          :ssl.close conn
        _ ->
      end
    end
  end

  defp new_state do
    %{conn: nil, sent_notifications: HashDict.new}
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
