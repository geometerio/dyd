defmodule Dyd.Gitlog do
  @moduledoc false
  use TypedStruct

  @typedoc "Represents an individual line from a git log"
  typedstruct do
    field(:sha, String.t(), enforce: true)
    field(:commit_datetime, String.t(), enforce: true)
    field(:age, String.t(), enforce: true)
    field(:author, String.t(), enforce: true)
    field(:message, String.t(), enforce: true)
  end

  def new(sha, commit_datetime, age, author, message),
    do:
      __struct__(
        sha: sha,
        commit_datetime: commit_datetime,
        age: age,
        author: author,
        message: message
      )
end
