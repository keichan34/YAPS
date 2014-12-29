defmodule Yaps.Adapter do
  @moduledoc """
  This module specifies the adapter API that an adapter is required to
  implement.
  """

  use Behaviour

  @type t :: module

  @doc """
  The callback invoked when the adapter is used.
  """
  defmacrocallback __using__(opts :: Keyword.t) :: Macro.t

  @doc """
  Starts any connection pooling or supervision and return `{:ok, pid}`
  or just `:ok` if nothing needs to be done.

  Returns `{:error, {:already_started, pid}}` if the repo already
  started or `{:error, term}` in case anything else goes wrong.
  """
  defcallback start_link(Yaps.Repo.t, Keyword.t) ::
              {:ok, pid} | :ok | {:error, {:already_started, pid}} | {:error, term}

  @doc """
  Stops any connection pooling or supervision started with `start_link/1`.
  """
  defcallback stop(Yaps.Repo.t) :: :ok
end
