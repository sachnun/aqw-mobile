use reqwest::{Client, Response};
use serde::Deserialize;
use std::fs;
use std::process::{Command, ExitStatus};
use std::fs::File;
use std::io::Write;

#[tokio::main]
async fn main() {
    match fs::remove_dir_all("assets") {
        Ok(()) => println!("File successfully deleted."),
        Err(error) => eprintln!("Error deleting file: {}", error),
    }

    match fs::create_dir("assets") {
        Ok(()) => println!("File successfully deleted."),
        Err(error) => eprintln!("Error deleting file: {}", error),
    }

    linear_download()
        .await
        .expect("Could not load Game.swf");

    let output: ExitStatus = Command::new("abcexport")
        .arg("assets/Game.swf")
        .status()
        .expect("failed to execute abcexport");

    println!("status: {}", output);

    let output: ExitStatus = Command::new("rabcdasm")
        .arg("assets/Game-0.abc")
        .status()
        .expect("failed to execute rabcdasm");

    println!("status: {}", output);
}

async fn linear_download() -> Result<(), Box<dyn std::error::Error>> {
    let client: Client = Client::new();

    let response: Response = client
        .get("https://game.aq.com/game/api/data/gameversion")
        .header("User-Agent", "Mozilla/5.0")
        .header("Accept", "application/json")
        .send()
        .await?;

    let text: String = response.text().await?;
    let game_version: GameVersion = serde_json::from_str(&text)?;

    println!("Downloading: {}", game_version.file);

    let mut downloaded_file: File = File::create("assets/Game.swf")?;

    let mut response: Response = client
        .get(format!(
            "https://game.aq.com/game/gamefiles/{}",
            game_version.file
        ))
        .header("User-Agent", "Mozilla/5.0")
        .send()
        .await?;

    while let Some(chunk) = response.chunk().await? {
        downloaded_file.write_all(&chunk)?;
    }

    Ok(())
}

#[derive(Debug, Deserialize)]
struct GameVersion {
    #[serde(rename = "sFile")]
    file: String,

    //#[serde(rename = "sTitle")]
    //title: String,

    //#[serde(rename = "sBG")]
    //bg: String,

    //#[serde(rename = "sVersion")]
    //version: String,
}
