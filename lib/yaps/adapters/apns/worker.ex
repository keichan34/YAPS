defmodule Yaps.Adapters.Apns.Worker do
  use GenServer

  @timeout 60

  def start(args) do
    GenServer.start(__MODULE__, args)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  ## GEN_SERVER LIFECYCLE ##

  def init(opts) do
    {:ok, conn} = :ssl.connect opts[:apns_gateway], opts[:apns_port], %{}, @timeout

    {:ok, Map.merge(new_state, %{conn: conn})}
  end

  def terminate(_reason, %{conn: conn}) do
    {_, _, pid} = conn
    if conn &&
      Process.alive?(pid) &&
      {:ok, _} == :ssl.connection_info(conn) do
      :ssl.close conn
    end
  end

  defp new_state do
    %{conn: nil}
  end
end
