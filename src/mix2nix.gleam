import gleam/io
import gleam/erlang/os
import gleam/erlang
import gleam/erlang/atom
import gleam/result
import gleam/bit_string
import gleam/bit_builder
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/function
import gleam/dynamic.{Dynamic}
import gleam/string
import gleam/hackney
import glint.{CommandInput}
import glint/flag
import gleam/http
import gleam/http/request.{Request}
import gleam/uri

pub fn main(argv: List(String)) {
  glint.new()
  |> glint.add_command(
    at: ["tar"],
    do: function.curry2(run_command)(tar),
    with: [
      flag.string(unflag(Pkg), "", ""),
      flag.string(unflag(Vsn), "", ""),
      flag.string(unflag(RepoKey), "", ""),
      flag.string(unflag(RepoName), "", ""),
      flag.string(unflag(RepoPublicKey), "", ""),
      flag.string(unflag(RepoUrl), "", ""),
      flag.string(unflag(RepoOrganization), "", ""),
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

type ThisModule {
  Mix2nix
}

type Flag {
  Pkg
  Vsn
  RepoKey
  RepoName
  RepoPublicKey
  RepoUrl
  RepoOrganization
  HttpAdapter
}

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
  use pkg <- result.then(req_arg(input, Pkg))
  use vsn <- result.then(req_arg(input, Vsn))
  use repo_key <- result.then(opt_arg(input, RepoKey))
  use repo_name <- result.then(opt_arg(input, RepoName))
  use repo_public_key <- result.then(opt_arg(input, RepoPublicKey))
  use repo_url <- result.then(opt_arg(input, RepoUrl))
  use repo_organization <- result.then(opt_arg(input, RepoOrganization))
  //
  // TODO : !!!
  //
  let assert Ok(_) =
    "hackney"
    |> atom.create_from_string
    |> erlang.ensure_all_started
  hc_default_config()
  |> hc_update_config(RepoKey, repo_key)
  |> hc_update_config(RepoName, repo_name)
  |> hc_update_config(RepoPublicKey, repo_public_key)
  |> hc_update_config(RepoUrl, repo_url)
  |> hc_update_config(RepoOrganization, repo_organization)
  |> hc_update_config(HttpAdapter, Some(#(Mix2nix, map.from_list([]))))
  |> hc_get_tarball(pkg, vsn)
  |> string.inspect
  //
  // TODO : !!!
  //
  |> io.println()
  |> Ok
}

//  def request(mtd, uri, reqhrs, reqbody, _) do
//    f =
//      if reqbody && reqbody != :undefined do
//        &:hackney.request(&1, &2, Map.to_list(&3), reqbody)
//      else
//        &:hackney.request(&1, &2, Map.to_list(&3))
//      end
//
//    with {:ok, 200 = ss, reshrs, ref} <- f.(mtd, uri, reqhrs),
//         {:ok, resbody} <- :hackney.body(ref) do
//      {:ok, {ss, Map.new(reshrs), resbody}}
//    end
//  end

pub fn request(
  mtd: http.Method,
  uri0: String,
  reqhrs: Map(String, String),
  reqbody: Dynamic,
  _: Map(Nil, Nil),
) -> Result(#(Int, Map(String, String), BitString), String) {
  use uri1 <-
    uri0
    |> uri.parse
    |> result.map_error(fn(_) { "Failed to parse Uri " <> uri0 })
    |> then
  use req0 <-
    uri1
    |> request.from_uri
    |> result.map_error(fn(_) { "Failed to parse Req " <> uri0 })
    |> then
  use res <-
    Request(
      method: mtd,
      headers: map.to_list(reqhrs),
      body: // TODO : reqbody is a dynamic tuple
      reqbody
      |> dynamic.bit_string
      |> result.unwrap(bit_string.from_string(""))
      |> bit_builder.from_bit_string,
      scheme: req0.scheme,
      host: req0.host,
      port: req0.port,
      path: req0.path,
      query: req0.query,
    )
    |> hackney.send_bits
    |> result.map_error(fn(err) { "Failed hackney " <> string.inspect(err) })
    |> then
  //
  // TODO : assert 200 !!!
  //
  Ok(#(res.status, map.from_list(res.headers), res.body))
}

fn then(x: Result(a, e)) -> fn(fn(a) -> Result(b, e)) -> Result(b, e) {
  function.curry2(result.then)(x)
}

fn hc_update_config(
  map: Map(a, Dynamic),
  key: a,
  new: Option(b),
) -> Map(a, Dynamic) {
  map.update(
    map,
    key,
    fn(old0) {
      // We want to fail in case where
      // config format has been changed.
      let assert Some(old) = old0
      new
      |> option.map(dynamic.from)
      |> option.unwrap(old)
    },
  )
}

external fn hc_default_config() -> Map(Flag, Dynamic) =
  "hex_core" "default_config"

external fn hc_get_tarball(
  Map(Flag, Dynamic),
  String,
  String,
) -> Result(#(Int, Dynamic, BitString), Dynamic) =
  "hex_repo" "get_tarball"
