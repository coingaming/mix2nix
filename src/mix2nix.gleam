import gleam/io
import gleam/erlang/os
import gleam/result
import gleam/option.{None, Option, Some}
import gleam/function
import gleam/string
import glint.{CommandInput}
import glint/flag

pub fn main(argv: List(String)) {
  glint.new()
  |> glint.add_command(
    at: ["tar"],
    do: function.curry2(run_command)(tar),
    with: [
      flag.string(unflag(Pkg), "", "Capitalize the provided name"),
      flag.string(unflag(Vsn), "", "Capitalize the provided name"),
    ],
    described: "Fetch package tar archive from hex repo.",
  )
  |> glint.run(case argv {
    [] ->
      "MIX2NIX_ARGV"
      |> os.get_env()
      |> result.map(fn(x) { string.split(x, " ") })
      |> result.unwrap([])
    xs -> xs
  })
}

fn run_command(
  action: fn(CommandInput) -> Result(Nil, String),
  input: CommandInput,
) {
  case action(input) {
    Error(err) -> io.println(err)
    Ok(Nil) -> io.println("Success!")
  }
}

type Flag {
  Pkg
  Vsn
}

// Org
// Prv
// Pub
// Url

fn unflag(x: Flag) {
  x
  |> string.inspect
  |> string.lowercase
}

fn opt_arg(input: CommandInput, flag: Flag) -> Result(Option(String), String) {
  let opt =
    flag.get(from: input.flags, for: unflag(flag))
    |> result.map(Some)
    |> result.unwrap(None)
  case opt {
    None -> Ok(None)
    Some(flag.S("")) -> Ok(None)
    Some(flag.S(x)) -> Ok(Some(x))
    _ -> Error("Non-string flag " <> unflag(flag))
  }
}

fn req_arg(input: CommandInput, flag: Flag) -> Result(String, String) {
  use x0 <-
    input
    |> opt_arg(flag)
    |> function.curry2(result.then)
  case x0 {
    None -> Error("Require flag " <> unflag(flag))
    Some(x) -> Ok(x)
  }
}

fn tar(input: CommandInput) -> Result(Nil, String) {
  use foo <- result.then(req_arg(input, Pkg))
  use bar <- result.then(opt_arg(input, Vsn))
  ["Hello ", ..input.args]
  |> string.join(foo)
  |> string.append(option.unwrap(bar, "EMPTY"))
  |> io.println()
  |> Ok
}
