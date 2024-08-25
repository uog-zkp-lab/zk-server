use anyhow::Result;
use apps::api::handle_generate_proof;
use dotenv::dotenv;
use warp::Filter;

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok(); // load .env file
    env_logger::init();
    tokio::task::block_in_place(|| {});

    let cors = warp::cors()
        .allow_origin("http://localhost:3000")
        .allow_any_origin()
        .allow_methods(vec!["GET", "POST", "OPTIONS"])
        .allow_headers(vec!["Content-Type"]);

    let generate_proof_route = warp::post()
        .and(warp::path("api"))
        .and(warp::path("generate_proof"))
        .and(warp::body::json())
        .and_then(handle_generate_proof);

    let routes = generate_proof_route.with(cors);

    // State the server here
    let port = 5566;
    println!("Server started at http://localhost:{}", port);
    warp::serve(routes).run(([127, 0, 0, 1], port)).await;
    Ok(())
}
