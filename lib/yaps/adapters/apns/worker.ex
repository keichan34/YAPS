defmodule Yaps.Adapters.Apns.Worker do
  use GenServer

  import Yaps.Adapters.Apns.BinaryUtils
  alias Yaps.Adapters.Apns.DataTransformers

  @timeout :infinity
  @error_messages %{
    0   => "No errors encountered",
    1   => "Processing error",
    2   => "Missing device token",
    3   => "Missing topic",
    4   => "Missing payload",
    5   => "Invalid token size",
    6   => "Invalid topic size",
    7   => "Invalid payload size",
    8   => "Invalid token",
    10  => "Shutdown",
    255 => "None (unknown)"
  }

  def start(args) do
    GenServer.start(__MODULE__, args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def send_push(worker, recipient, payload, opts \\ []) do
    GenServer.cast(worker, {:send_push, recipient, payload, opts})
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
    << 8 :: bytes(1), status_code :: bytes(1), _identifier :: binary >> = \
      List.to_string(raw_data)

    if status_code == 0 do
      {:noreply, s}
    else
      message = Map.get(@error_messages, status_code,
        "Unknown status code: #{status_code}")
      {:stop, {:apns_error, message}, s}
    end
  end

  def handle_info({:ssl_closed, _socket}, s) do
    {:stop, :ssl_closed, s}
  end

  def handle_cast({:send_push, recipient, payload, opts}, %{conn: conn} = s) do
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

    {:noreply, s}
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
