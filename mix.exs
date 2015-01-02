defmodule Yaps.Mixfile do
  use Mix.Project

  def project do
    [app: :yaps,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps,
     build_per_environment: false,
     name: "YAPS",
     source_url: "https://github.com/keichan34/yaps",
     docs: fn ->
       {ref, 0} = System.cmd("git", ["rev-parse", "--verify", "--quiet", "HEAD"])
       [source_ref: ref, main: "README", readme: true]
     end,
     description: description,
     package: package]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:ssl, :poolboy]]
  end

  defp deps do
    [{:ex_doc, only: :dev},
     {:earmark, only: :dev},
     {:poolboy, "~> 1.4.1"}]
  end

  defp description do
    """
    Yet Another Push-message Scheduler / Sender
    """
  end

  defp package do
    [contributors: ["Keitaroh Kobayashi"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/keichan34/yaps"}]
  end
end
