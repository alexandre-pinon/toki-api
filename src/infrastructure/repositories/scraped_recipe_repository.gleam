import domain/entities/scraped_recipe.{type ScrapedRecipe}
import gleam/bool
import gleam/http
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import infrastructure/decoders/scraped_recipe_decoder
import infrastructure/errors.{
  type RequestError, BodyDecodingFailed, HttpError, InvalidUrl,
  WebsiteNotSupported,
}

pub fn scrape_recipe(
  url: String,
  on recipe_scraper_url: String,
  with identity_token: Option(String),
) -> Result(ScrapedRecipe, RequestError) {
  use req <- result.try(
    uri.parse(recipe_scraper_url)
    |> result.map(request.from_uri)
    |> result.flatten
    |> result.replace_error(InvalidUrl(recipe_scraper_url)),
  )

  let req =
    req
    |> request.set_method(http.Post)
    |> request.set_header("Content-type", "application/json")
    |> set_auth_header_if_needed(identity_token)
    |> request.set_body(
      [#("url", json.string(url))]
      |> json.object
      |> json.to_string,
    )

  use res <- result.try(httpc.send(req) |> result.map_error(HttpError))

  use <- bool.guard(res.status == 422, Error(WebsiteNotSupported(url)))

  res.body
  |> json.decode(scraped_recipe_decoder.new())
  |> result.map(scraped_recipe_decoder.from_raw_to_domain)
  |> result.map_error(BodyDecodingFailed)
}

fn set_auth_header_if_needed(
  req: Request(body),
  identity_token: Option(String),
) -> Request(body) {
  case identity_token {
    Some(identity_token) ->
      req |> request.set_header("Authorization", "Bearer " <> identity_token)
    None -> req
  }
}
