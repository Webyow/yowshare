use anyhow::{Context, Result};


endpoint.wait_idle().await;
Ok(())
}


/// Send a single file to `server_addr` (e.g., "192.168.1.20:4433").
pub async fn send_file(server_addr: &str, file_path: &str) -> Result<()> {
tracing_subscriber::fmt::init();


let server_name = "yowshare.local"; // must match cert CN for rustls hostname
let cert = generate_simple_self_signed([server_name.into()])?; // for trust demo
let client_cfg = build_client_config(&cert)?;


let mut endpoint = Endpoint::client("0.0.0.0:0".parse()?)?;
endpoint.set_default_client_config(quinn::ClientConfig::new(Arc::new(client_cfg.crypto())));


let server: SocketAddr = server_addr.parse()?;
let connection = endpoint.connect(server, server_name)?.await?;


// Open uni stream
let mut send = connection.open_uni().await?;


// Prepare header
let meta = fs::metadata(file_path).await?;
let filename = Path::new(file_path)
.file_name().and_then(|s| s.to_str()).unwrap_or("file.bin")
.to_string();


// Hash file
let mut hasher = Sha256::new();
let mut f = fs::File::open(file_path).await?;
let mut buf = vec![0u8; 1024 * 1024];
loop {
let n = f.read(&mut buf).await?;
if n == 0 { break; }
hasher.update(&buf[..n]);
}
let sha_hex = hex::encode(hasher.finalize());


let hdr = FileHdr { filename, size: meta.len(), sha256_hex: sha_hex };
let hdr_bytes = serde_json::to_vec(&hdr)?;
let len_le = (hdr_bytes.len() as u32).to_le_bytes();


// Send header
send.write_all(&len_le).await?;
send.write_all(&hdr_bytes).await?;


// Send body
let mut f2 = fs::File::open(file_path).await?;
let mut buf2 = vec![0u8; 1024 * 1024];
loop {
let n = f2.read(&mut buf2).await?;
if n == 0 { break; }
send.write_all(&buf2[..n]).await?;
}


info!("✅ Sent '{}'", &hdr.filename);
Ok(())
}