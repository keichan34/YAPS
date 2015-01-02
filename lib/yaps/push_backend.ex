defmodule Yaps.PushBackend do
  @moduledoc """
  This module is used to define a push backend service.

  When used, the following options are allowed:

  * `:adapter` - the adapter to be used for the backend.

  * `:env` - configures the repository to support environments

  ## Example

      defmodule APNSBackend do
        use Yaps.PushBackend, adapter: Yaps.Adapters.Apns

        def conf do
          [
            certfile: "/path/to/certificate",
            keyfile: "/path/to/key"
          ]
        end
      end

  Most of the time, we want the repository to work with different
  environments. In such cases, we can pass an `:env` option:

      defmodule APNSBackend do
        use Yaps.PushBackend, adapter: Yaps.Adapters.Apns, env: Mix.env

        def conf(:prod) do
          [
            certfile: "/path/to/production/certificate",
            keyfile: "/path/to/production/key"
          ]
        end

        def conf(:dev) do
          [
            certfile: "/path/to/development/certificate",
            keyfile: "/path/to/development/key"
          ]
        end
      end

  Notice that, when using the environment, developers should implement
  `conf/1` which automatically passes the environment instead of `conf/0`.

  Note the environment is only used at compilation time. That said, make
  sure the `:build_per_environment` option is set to true (the default)
  in your Mix project configuration.
  """

  use Behaviour
  @type t :: module

  defmacro __using__(opts) do
    adapter = Macro.expand(Keyword.fetch!(opts, :adapter), __CALLER__)
    env     = Keyword.get(opts, :env)

    quote do
      use unquote(adapter)
      @behaviour Yaps.PushBackend
      @env unquote(env)

      import Application, only: [app_dir: 2]

      if @env do
        def conf do
          conf(@env)
        end
        defoverridable conf: 0
      end

      def start_link do
        Yaps.PushBackend.Backend.start_link(__MODULE__, unquote(adapter))
      end

      def stop do
        Yaps.PushBackend.Backend.stop(__MODULE__, unquote(adapter))
      end

      def send_push(recipient, payload, opts \\ []) do
        Yaps.PushBackend.Backend.send_push(
          __MODULE__,
          unquote(adapter),
          recipient,
          payload,
          opts
        )
      end

      def adapter do
        unquote(adapter)
      end
    end
  end

  @doc """
  Should return the options that will be given to the push backend adapter. This
  function must be implemented by the user.
  """
  defcallback conf() :: Keyword.t

  @doc """
  Starts any connection pooling or supervision and return `{:ok, pid}`
  or just `:ok` if nothing needs to be done.

  Returns `{:error, {:already_started, pid}}` if the repo already
  started or `{:error, term}` in case anything else goes wrong.
  """
  defcallback start_link() :: {:ok, pid} | :ok |
                              {:error, {:already_started, pid}} |
                              {:error, term}

  @doc """
  Stops any connection pooling or supervision started with `start_link/1`.
  """
  defcallback stop() :: :ok

  @doc """
  Sends a push notification.
  """
  defcallback send_push(Bitstring, Bitstring, Keyword.t) :: :ok | {:error, term}

  @doc """
  Returns the adapter this backend is configured to use.
  """
  defcallback adapter() :: Yaps.Adapter.t
end
