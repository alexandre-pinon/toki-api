import domain/entities/scraped_recipe.{type ScrapedRecipe}
import env.{type RecipeScraperConfig, Dev, Prod}
import gleam/bool
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import infrastructure/decoders/scraped_recipe_decoder
import infrastructure/errors.{
  type RequestError, BodyDecodingFailed, HttpError, WebsiteNotSupported,
}

pub fn scrape_recipe(
  url: String,
  using recipe_scraper_config: RecipeScraperConfig,
  given gleam_env: env.GleamEnv,
) -> Result(ScrapedRecipe, RequestError) {
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_port(recipe_scraper_config.port)
    |> request.set_host(recipe_scraper_config.host)
    |> request.set_path("/scrape_recipe")
    |> request.set_scheme({
      case gleam_env {
        Dev -> http.Http
        Prod -> http.Https
      }
    })
    |> request.set_header("Content-type", "application/json")
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
