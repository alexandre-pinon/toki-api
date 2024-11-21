import application/context.{type Context}
import domain/entities/scraped_recipe.{type ScrapedRecipe}
import env.{Dev, Prod}
import gleam/dynamic.{type Dynamic}
import gleam/http/request
import gleam/httpc
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri
import infrastructure/errors.{type HttpError}
import infrastructure/repositories/scraped_recipe_repository

pub type ImportRecipeUseCasePort {
  ImportRecipeUseCasePort(url: String)
}

pub type ImportRecipeUseCaseResult =
  ScrapedRecipe

pub type ImportRecipeUseCaseErrors {
  FetchIdTokenFailed(reason: Dynamic)
  ScrapingFailed(reason: HttpError)
}

pub fn execute(
  port: ImportRecipeUseCasePort,
  ctx: Context,
) -> Result(ImportRecipeUseCaseResult, ImportRecipeUseCaseErrors) {
  use id_token <- result.try(case ctx.gleam_env {
    Dev -> Ok(None)
    Prod -> fetch_id_token(ctx)
  })

  scraped_recipe_repository.scrape_recipe(
    port.url,
    ctx.recipe_scraper_url,
    id_token,
  )
  |> result.map_error(ScrapingFailed)
}

fn fetch_id_token(
  ctx: Context,
) -> Result(Option(String), ImportRecipeUseCaseErrors) {
  case ctx.google_metadata_url {
    Some(url) -> {
      use req <- result.try(
        uri.parse(url)
        |> result.then(request.from_uri)
        |> result.map(request.set_header(_, "Metadata-Flavor", "Google"))
        |> result.map(request.set_query(_, [
          #("audience", ctx.recipe_scraper_url),
        ]))
        |> result.replace_error(
          FetchIdTokenFailed(dynamic.from("url is invalid")),
        ),
      )

      httpc.send(req)
      |> result.map(fn(res) { Some(res.body) })
      |> result.map_error(FetchIdTokenFailed)
    }
    None -> Error(FetchIdTokenFailed(dynamic.from("url is missing")))
  }
}
