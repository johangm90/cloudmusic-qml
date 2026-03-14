use aes::Aes128;
use base64::Engine;
use cbc::Encryptor;
use cipher::block_padding::Pkcs7;
use cipher::{BlockEncryptMut, KeyIvInit};
use reqwest::blocking::Client;
use reqwest::header::{HeaderName, HeaderValue, COOKIE, REFERER, USER_AGENT};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::thread;
use std::time::Duration;
use tiny_http::{Header, Method, Request, Response, Server, StatusCode};

const LISTEN_ADDR: &str = "127.0.0.1:39876";
const MUSIC_BASE: &str = "http://music.163.com";
const MEDIA_BASE: &str = "http://p3.music.126.net/";
const UA: &str = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 CloudMusic/0.1.1 NeteaseMusic/8.2.30";
const COOKIE_VALUE: &str = "appver=8.2.30; os=iPhone OS; osver=15.0; EVNSM=1.0.0; buildver=2206; channel=distribution; machineid=iPhone13.3";
const WEAPI_NONCE: &str = "0CoJUm6Qyw8W8jud";
const WEAPI_SKEY: &str = "B3v3kH4vRPWRJFfH";
const WEAPI_IV: &str = "0102030405060708";
const WEAPI_ENCSEC_KEY: &str = "85302b818aea19b68db899c25dac229412d9bba9b3fcfe4f714dc016bc1686fc446a08844b1f8327fd9cb623cc189be00c5a365ac835e93d4858ee66f43fdc59e32aaed3ef24f0675d70172ef688d376a4807228c55583fe5bac647d10ecef15220feef61477c28cae8406f6f9896ed329d6db9f88757e31848a6c2ce2f94308";

// ── YouTube Music / InnerTube constants ──────────────────────────────────────
const INNERTUBE_API_KEY: &str = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX3";
const INNERTUBE_BASE: &str = "https://music.youtube.com/youtubei/v1/";
const INNERTUBE_CLIENT_NAME: &str = "WEB_REMIX";
const INNERTUBE_CLIENT_ID: &str = "67";
const INNERTUBE_CLIENT_VERSION: &str = "1.20250310.01.00";
const INNERTUBE_USER_AGENT: &str =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0";

pub fn direct_call(action: &str, params_json: &str) -> String {
    let params: Value = serde_json::from_str(params_json).unwrap_or_else(|_| json!({}));
    let client = match Client::builder().timeout(Duration::from_secs(20)).build() {
        Ok(c) => c,
        Err(err) => return json!({"error": err.to_string()}).to_string(),
    };

    let get_str = |key: &str| -> String {
        params
            .get(key)
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string()
    };
    let get_i64 = |key: &str, default: i64| -> i64 {
        params.get(key).and_then(Value::as_i64).unwrap_or(default)
    };

    let result = match action {
        "search" => {
            let query = get_str("query");
            let kind = get_str("type");
            let limit = get_i64("limit", 50).to_string();
            let body = [
                ("s", query),
                (
                    "type",
                    if kind.is_empty() {
                        "1".to_string()
                    } else {
                        kind
                    },
                ),
                ("offset", "0".to_string()),
                ("limit", limit),
            ];
            music_post_form(&client, "/api/search/get", &body).and_then(|raw| {
                parse_json_loose(&raw).map(|v| normalize_search_payload(&v).to_string())
            })
        }
        "getNewAlbums" => {
            let limit = get_i64("limit", 50);
            music_get(
                &client,
                &format!("/api/album/new?area=ALL&offset=0&total=true&limit={limit}"),
            )
            .and_then(|raw| {
                parse_json_loose(&raw).map(|v| {
                    let albums = v
                        .get("albums")
                        .and_then(Value::as_array)
                        .map(|arr| arr.iter().map(normalize_album).collect::<Vec<Value>>())
                        .unwrap_or_default();
                    json!({ "albums": albums })
                })
            })
            .map(|v| v.to_string())
        }
        "getTopArtists" => {
            let limit = get_i64("limit", 50);
            music_get(
                &client,
                &format!("/api/artist/top?offset=0&total=false&limit={limit}"),
            )
            .and_then(|raw| {
                parse_json_loose(&raw).map(|v| {
                    let artists = v
                        .get("artists")
                        .and_then(Value::as_array)
                        .map(|arr| arr.iter().map(normalize_artist).collect::<Vec<Value>>())
                        .unwrap_or_default();
                    json!({ "artists": artists })
                })
            })
            .map(|v| v.to_string())
        }
        "getArtistTopSongs" => {
            let id = get_str("id");
            music_get(&client, &format!("/api/artist/{id}?offset=0&limit=100"))
                .and_then(|raw| {
                    parse_json_loose(&raw).map(|v| {
                        let artist = normalize_artist(v.get("artist").unwrap_or(&Value::Null));
                        let songs = v
                            .get("hotSongs")
                            .and_then(Value::as_array)
                            .map(|arr| arr.iter().map(normalize_song).collect::<Vec<Value>>())
                            .unwrap_or_default();
                        json!({ "artist": artist, "songs": songs })
                    })
                })
                .map(|v| v.to_string())
        }
        "getArtistAlbums" => {
            let id = get_str("id");
            music_get(
                &client,
                &format!("/api/artist/albums/{id}?offset=0&limit=100"),
            )
            .and_then(|raw| {
                parse_json_loose(&raw).map(|v| {
                    let artist = normalize_artist(v.get("artist").unwrap_or(&Value::Null));
                    let albums = v
                        .get("hotAlbums")
                        .and_then(Value::as_array)
                        .map(|arr| arr.iter().map(normalize_album).collect::<Vec<Value>>())
                        .unwrap_or_default();
                    json!({ "artist": artist, "albums": albums })
                })
            })
            .map(|v| v.to_string())
        }
        "getAlbumDetail" => {
            let id = get_str("id");
            music_get(&client, &format!("/api/album/{id}"))
                .and_then(|raw| {
                    parse_json_loose(&raw).map(|v| {
                        let album_src = v.get("album").unwrap_or(&Value::Null);
                        let songs = album_src
                            .get("songs")
                            .and_then(Value::as_array)
                            .map(|arr| arr.iter().map(normalize_song).collect::<Vec<Value>>())
                            .unwrap_or_default();
                        json!({
                            "album": normalize_album(album_src),
                            "songs": songs
                        })
                    })
                })
                .map(|v| v.to_string())
        }
        "songDetail" => {
            let id = get_str("id");
            song_detail_value(&id, &client).map(|v| v.to_string())
        }
        "lyric" => {
            let id = get_str("id");
            lyric_value(&id, &client).map(|v| v.to_string())
        }
        "downloadUrl" => {
            let id = get_str("id");
            let quality = get_str("quality");
            let q = if quality.is_empty() {
                "96"
            } else {
                quality.as_str()
            };
            resolve_stream_data(&id, q, &client)
                .map(|data| json!({"url": data.mp3, "img": data.img}).to_string())
        }
        "ytmusic_search" => {
            let q = params.get("q").and_then(Value::as_str).unwrap_or("");
            let limit = params.get("limit").and_then(Value::as_u64).unwrap_or(20) as usize;
            Ok(innertube_search(q, limit, &client).to_string())
        }
        "ytmusic_song" => {
            let id = params.get("id").and_then(Value::as_str).unwrap_or("");
            match innertube_stream_url(id, &client) {
                Ok(data) => Ok(json!({
                    "id": id,
                    "title": data.song_name,
                    "artist": data.artist,
                    "album": data.album,
                    "img": data.img,
                    "duration": data.duration,
                    "source": "youtube",
                    "url": data.mp3
                })
                .to_string()),
                Err(e) => Ok(json!({"error": e}).to_string()),
            }
        }
        _ => Err("unsupported action".to_string()),
    };

    match result {
        Ok(v) => v,
        Err(err) => json!({"error": err}).to_string(),
    }
}

pub fn spawn_local_api_server() {
    thread::spawn(|| {
        let server = match Server::http(LISTEN_ADDR) {
            Ok(s) => s,
            Err(err) => {
                eprintln!("Failed to start local API server on {LISTEN_ADDR}: {err}");
                return;
            }
        };
        let client = match Client::builder().timeout(Duration::from_secs(20)).build() {
            Ok(c) => c,
            Err(err) => {
                eprintln!("Failed to create HTTP client: {err}");
                return;
            }
        };
        for request in server.incoming_requests() {
            handle_request(request, &client);
        }
    });
}

fn handle_request(request: Request, client: &Client) {
    let method = request.method().clone();
    let url = request.url().to_string();
    let (path, query) = split_path_query(&url);
    let params = parse_query(query);

    // Extract Range header (needed for YouTube byte-range proxy)
    let range_header: Option<String> = request
        .headers()
        .iter()
        .find(|h| h.field.equiv("Range"))
        .map(|h| h.value.as_str().to_string());

    let response = match (method, path) {
        (Method::Get, p) if p.starts_with("/play/youtube/") => {
            handle_play_youtube(p, range_header.as_deref(), client)
        }
        (Method::Get, p) if p.starts_with("/url/youtube/") => handle_url_youtube(p, client),
        (Method::Get, p) if p.starts_with("/play/") => handle_play(p, client),
        (Method::Get, p) if p.starts_with("/url/") => handle_url(p, client),
        (Method::Get, p) if p.starts_with("/song/") => handle_song_detail_endpoint(p, client),
        (Method::Get, p) if p.starts_with("/pic/") => handle_pic(p, query),
        (Method::Get, "/") => handle_query_actions(params, client),
        _ => json_response(StatusCode(404), json!({"error":"not found"})),
    };

    let _ = request.respond(response);
}

fn split_path_query(url: &str) -> (&str, &str) {
    match url.find('?') {
        Some(pos) => (&url[..pos], &url[pos + 1..]),
        None => (url, ""),
    }
}

fn parse_query(query: &str) -> HashMap<String, String> {
    let mut out = HashMap::new();
    for pair in query.split('&') {
        if pair.is_empty() {
            continue;
        }
        let mut it = pair.splitn(2, '=');
        let k = it.next().unwrap_or_default();
        let v = it.next().unwrap_or_default();
        let key = urlencoding::decode(k)
            .map(|s| s.into_owned())
            .unwrap_or_default();
        let value = urlencoding::decode(v)
            .map(|s| s.into_owned())
            .unwrap_or_default();
        out.insert(key, value);
    }
    out
}

fn default_headers(req: reqwest::blocking::RequestBuilder) -> reqwest::blocking::RequestBuilder {
    let mut out = req
        .header(USER_AGENT, UA)
        .header(REFERER, MUSIC_BASE)
        .header(COOKIE, COOKIE_VALUE);
    let x_real_ip = HeaderName::from_static("x-real-ip");
    if let Ok(v) = HeaderValue::from_str(&random_cn_ip()) {
        out = out.header(x_real_ip, v);
    }
    out
}

fn random_cn_ip() -> String {
    // Same range used by Meting: long2ip(mt_rand(1884815360, 1884890111))
    let low: u32 = 1_884_815_360;
    let high: u32 = 1_884_890_111;
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.subsec_nanos())
        .unwrap_or(0);
    let range = high.saturating_sub(low).max(1);
    let val = low + (now % range);
    format!(
        "{}.{}.{}.{}",
        (val >> 24) & 0xff,
        (val >> 16) & 0xff,
        (val >> 8) & 0xff,
        val & 0xff
    )
}

fn music_get(client: &Client, path_or_url: &str) -> Result<String, String> {
    let url = if path_or_url.starts_with("http") {
        path_or_url.to_string()
    } else {
        format!("{MUSIC_BASE}{path_or_url}")
    };
    let req = default_headers(client.get(url));
    req.send()
        .map_err(|e| e.to_string())?
        .text()
        .map_err(|e| e.to_string())
}

fn music_post_form(client: &Client, path: &str, form: &[(&str, String)]) -> Result<String, String> {
    let req = default_headers(client.post(format!("{MUSIC_BASE}{path}"))).form(form);
    req.send()
        .map_err(|e| e.to_string())?
        .text()
        .map_err(|e| e.to_string())
}

fn handle_query_actions(
    params: HashMap<String, String>,
    client: &Client,
) -> Response<std::io::Cursor<Vec<u8>>> {
    if let Some(id) = params.get("lyric") {
        return handle_lyric(id, client);
    }
    if let Some(id) = params.get("offline") {
        let quality = params.get("quality").map(String::as_str).unwrap_or("320");
        return handle_offline(id, quality, client);
    }
    if let Some(id) = params.get("stream") {
        let quality = params.get("quality").map(String::as_str).unwrap_or("320");
        return handle_stream(id, quality, client);
    }
    if let Some(action) = params.get("action") {
        match action.as_str() {
            "search" => {
                let query = params.get("query").cloned().unwrap_or_default();
                let song_type = params
                    .get("type")
                    .cloned()
                    .unwrap_or_else(|| "1".to_string());
                let limit = params
                    .get("limit")
                    .cloned()
                    .unwrap_or_else(|| "50".to_string());
                let body = [
                    ("s", query),
                    ("type", song_type),
                    ("offset", "0".to_string()),
                    ("limit", limit),
                ];
                return proxy_post_form(client, "/api/search/get", &body);
            }
            "getNewAlbums" => {
                let limit = params
                    .get("limit")
                    .cloned()
                    .unwrap_or_else(|| "50".to_string());
                return proxy_get(
                    client,
                    &format!("/api/album/new?area=ALL&offset=0&total=true&limit={limit}"),
                );
            }
            "getTopArtists" => {
                let limit = params
                    .get("limit")
                    .cloned()
                    .unwrap_or_else(|| "50".to_string());
                return proxy_get(
                    client,
                    &format!("/api/artist/top?offset=0&total=false&limit={limit}"),
                );
            }
            "getArtistTopSongs" => {
                let id = params.get("id").cloned().unwrap_or_default();
                return proxy_get(client, &format!("/api/artist/{id}?offset=0&limit=100"));
            }
            "getArtistAlbums" => {
                let id = params.get("id").cloned().unwrap_or_default();
                return proxy_get(
                    client,
                    &format!("/api/artist/albums/{id}?offset=0&limit=100"),
                );
            }
            "getAlbumDetail" => {
                let id = params.get("id").cloned().unwrap_or_default();
                return proxy_get(client, &format!("/api/album/{id}"));
            }
            "getSongDetail" => {
                let id = params.get("id").cloned().unwrap_or_default();
                return handle_song_detail_legacy(&id, client);
            }
            "ytmusic_search" => {
                let query = params.get("q").cloned().unwrap_or_default();
                let limit = params
                    .get("limit")
                    .and_then(|v| v.parse::<usize>().ok())
                    .unwrap_or(20);
                let result = innertube_search(&query, limit, client);
                return json_response(StatusCode(200), result);
            }
            "ytmusic_song" => {
                let id = params.get("id").cloned().unwrap_or_default();
                match innertube_stream_url(&id, client) {
                    Ok(data) => {
                        return json_response(
                            StatusCode(200),
                            json!({
                                "id": id,
                                "title": data.song_name,
                                "artist": data.artist,
                                "album": data.album,
                                "img": data.img,
                                "duration": data.duration,
                                "source": "youtube",
                                "url": data.mp3
                            }),
                        );
                    }
                    Err(err) => {
                        return json_response(StatusCode(502), json!({"error": err}));
                    }
                }
            }
            _ => {}
        }
    }
    json_response(StatusCode(400), json!({"error":"invalid request"}))
}

fn handle_lyric(id: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    match lyric_value(id, client) {
        Ok(v) => json_response(StatusCode(200), v),
        Err(err) => json_response(StatusCode(502), json!({"error": err})),
    }
}

fn lyric_value(id: &str, client: &Client) -> Result<Value, String> {
    let primary = format!("/api/song/lyric?id={id}&os=linux&lv=-1&kv=-1&tv=-1");
    let fallback = format!("/api/song/media?id={id}");
    let raw = match music_get(client, &primary) {
        Ok(body) => body,
        Err(_) => match music_get(client, &fallback) {
            Ok(body) => body,
            Err(err) => return Err(err),
        },
    };
    let data = parse_json_loose(&raw)?;
    let lyric = data
        .get("lrc")
        .and_then(|l| l.get("lyric"))
        .and_then(Value::as_str)
        .or_else(|| data.get("lyric").and_then(Value::as_str))
        .unwrap_or("")
        .to_string();
    let tlyric = data
        .get("tlyric")
        .and_then(|l| l.get("lyric"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    Ok(json!({ "lyric": lyric, "tlyric": tlyric }))
}

fn proxy_get(client: &Client, path: &str) -> Response<std::io::Cursor<Vec<u8>>> {
    match music_get(client, path) {
        Ok(body) => plain_json_response(StatusCode(200), body),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn proxy_post_form(
    client: &Client,
    path: &str,
    form: &[(&str, String)],
) -> Response<std::io::Cursor<Vec<u8>>> {
    match music_post_form(client, path, form) {
        Ok(body) => plain_json_response(StatusCode(200), body),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn handle_song_detail_legacy(id: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    match get_song_detail_raw(id, client) {
        Ok(song) => {
            let artist = song
                .get("artists")
                .and_then(Value::as_array)
                .and_then(|arr| arr.first())
                .and_then(|a| a.get("name"))
                .and_then(Value::as_str)
                .unwrap_or("")
                .to_string();
            let artist_id = song
                .get("artists")
                .and_then(Value::as_array)
                .and_then(|arr| arr.first())
                .and_then(|a| a.get("id"))
                .and_then(Value::as_i64)
                .unwrap_or(0);
            let album = song.get("album").cloned().unwrap_or(Value::Null);
            let duration = read_song_duration_ms(&song);
            let result = json!({
                "artist_id": artist_id,
                "album_id": album.get("id").and_then(Value::as_i64).unwrap_or(0),
                "duration": duration,
                "name": song.get("name").and_then(Value::as_str).unwrap_or(""),
                "artist": artist,
                "album": album.get("name").and_then(Value::as_str).unwrap_or(""),
                "picUrl": album.get("picUrl").and_then(Value::as_str).unwrap_or(""),
                "source": "netease"
            });
            json_response(StatusCode(200), result)
        }
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn normalize_search_payload(raw: &Value) -> Value {
    let result = raw.get("result").unwrap_or(&Value::Null);
    let songs = result
        .get("songs")
        .and_then(Value::as_array)
        .map(|arr| arr.iter().map(normalize_song).collect::<Vec<Value>>())
        .unwrap_or_default();
    let albums = result
        .get("albums")
        .and_then(Value::as_array)
        .map(|arr| arr.iter().map(normalize_album).collect::<Vec<Value>>())
        .unwrap_or_default();
    let artists = result
        .get("artists")
        .and_then(Value::as_array)
        .map(|arr| arr.iter().map(normalize_artist).collect::<Vec<Value>>())
        .unwrap_or_default();
    json!({
        "songs": songs,
        "albums": albums,
        "artists": artists
    })
}

fn normalize_artist(artist: &Value) -> Value {
    let pic_url = artist
        .get("picUrl")
        .or_else(|| artist.get("img1v1Url"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    let image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        format!("{pic_url}?param=200y200")
    };
    let big_image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        pic_url
    };
    json!({
        "id": artist.get("id").and_then(Value::as_i64).unwrap_or(0),
        "name": artist.get("name").and_then(Value::as_str).unwrap_or(""),
        "image": image,
        "big_image": big_image,
        "source": "netease"
    })
}

fn normalize_album(album: &Value) -> Value {
    let artist_name = album
        .get("artist")
        .and_then(|a| a.get("name"))
        .and_then(Value::as_str)
        .or_else(|| {
            album
                .get("artists")
                .and_then(Value::as_array)
                .and_then(|arr| arr.first())
                .and_then(|a| a.get("name"))
                .and_then(Value::as_str)
        })
        .unwrap_or("")
        .to_string();
    let pic_url = album
        .get("picUrl")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    let image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        format!("{pic_url}?param=200y200")
    };
    let big_image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        pic_url
    };
    json!({
        "id": album.get("id").and_then(Value::as_i64).unwrap_or(0),
        "name": album.get("name").and_then(Value::as_str).unwrap_or(""),
        "artist": artist_name,
        "size": album.get("size").and_then(Value::as_i64).unwrap_or(0),
        "publish_time": album.get("publishTime").and_then(Value::as_i64).unwrap_or(0),
        "image": image,
        "big_image": big_image,
        "source": "netease"
    })
}

fn normalize_song(song: &Value) -> Value {
    let artists = song
        .get("artists")
        .or_else(|| song.get("ar"))
        .and_then(Value::as_array);
    let artist_id = artists
        .and_then(|arr| arr.first())
        .and_then(|a| a.get("id"))
        .and_then(Value::as_i64)
        .unwrap_or(0);
    let artist_name = artists
        .and_then(|arr| arr.first())
        .and_then(|a| a.get("name"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    let album = song
        .get("album")
        .or_else(|| song.get("al"))
        .cloned()
        .unwrap_or(Value::Null);
    let pic_url = album
        .get("picUrl")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();
    let image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        format!("{pic_url}?param=120y120")
    };
    let big_image = if pic_url.is_empty() {
        "../graphics/default.png".to_string()
    } else {
        pic_url
    };
    json!({
        "id": song.get("id").and_then(Value::as_i64).unwrap_or(0),
        "name": song.get("name").and_then(Value::as_str).unwrap_or(""),
        "album_id": album.get("id").and_then(Value::as_i64).unwrap_or(0),
        "album": album.get("name").and_then(Value::as_str).unwrap_or(""),
        "artist_id": artist_id,
        "artist": artist_name,
        "duration": read_song_duration_ms(song),
        "image": image,
        "big_image": big_image,
        "source": "netease"
    })
}

fn song_detail_value(id: &str, client: &Client) -> Result<Value, String> {
    let song = get_song_detail_raw(id, client)?;
    Ok(json!({
        "song": normalize_song(&song)
    }))
}

fn handle_song_detail_endpoint(path: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    let id = path.trim_start_matches("/song/").trim();
    match song_detail_value(id, client) {
        Ok(payload) => json_response(StatusCode(200), payload),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn handle_url(path: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    let chunks: Vec<&str> = path.split('/').collect();
    if chunks.len() < 4 {
        return json_response(StatusCode(400), json!({"error":"invalid url path"}));
    }
    let id = chunks[2];
    let quality = chunks[3];
    match resolve_stream_data(id, quality, client) {
        Ok(data) => json_response(StatusCode(200), json!({"url": data.mp3, "img": data.img})),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn handle_play(path: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    let chunks: Vec<&str> = path.split('/').collect();
    if chunks.len() < 4 {
        return json_response(StatusCode(400), json!({"error":"invalid play path"}));
    }
    let id = chunks[2];
    let quality = chunks[3];
    match resolve_stream_data(id, quality, client) {
        Ok(data) => redirect_response(&data.mp3),
        Err(err) => {
            eprintln!("local_api /play failed song {} q={}: {}", id, quality, err);
            json_response(StatusCode(502), json!({"error":err}))
        }
    }
}

fn handle_offline(id: &str, quality: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    match resolve_stream_data(id, quality, client) {
        Ok(data) => json_response(StatusCode(200), json!({ "mp3": data.mp3, "img": data.img })),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn handle_stream(id: &str, quality: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    match resolve_stream_data(id, quality, client) {
        Ok(data) => json_response(
            StatusCode(200),
            json!({
                "cancion": data.song_name,
                "artista": data.artist,
                "album": data.album,
                "duracion": data.duration,
                "mp3": data.mp3,
                "img": data.img
            }),
        ),
        Err(err) => json_response(StatusCode(502), json!({"error":err})),
    }
}

fn handle_pic(path: &str, query: &str) -> Response<std::io::Cursor<Vec<u8>>> {
    let pic_id = path.trim_start_matches("/pic/").trim();
    if pic_id.is_empty() {
        return json_response(StatusCode(400), json!({"error":"missing pic id"}));
    }
    let params = parse_query(query);
    let size = params
        .get("size")
        .and_then(|v| v.parse::<u32>().ok())
        .filter(|v| *v > 0)
        .unwrap_or(300);
    let enc = decrypt_id(pic_id);
    redirect_response(&format!(
        "{MEDIA_BASE}{enc}/{pic_id}.jpg?param={size}y{size}"
    ))
}

struct StreamData {
    song_name: String,
    artist: String,
    album: String,
    duration: i64,
    img: String,
    mp3: String,
}

fn resolve_stream_data(id: &str, quality: &str, client: &Client) -> Result<StreamData, String> {
    let song = get_song_detail_raw(id, client)?;
    let album = song.get("album").cloned().unwrap_or(Value::Null);
    let mp3 = match resolve_play_url_weapi(id, quality, client) {
        Ok(url) if !url.is_empty() => url,
        Err(err) => {
            eprintln!("local_api weapi failed for song {id} q={quality}: {err}");
            match resolve_stream_data_legacy_dfs(id, quality, client) {
                Ok(url) => url,
                Err(dfs_err) => {
                    eprintln!("local_api dfs fallback failed for song {id} q={quality}: {dfs_err}");
                    resolve_outer_url(id, client)?
                }
            }
        }
        _ => match resolve_stream_data_legacy_dfs(id, quality, client) {
            Ok(url) => url,
            Err(_) => resolve_outer_url(id, client)?,
        },
    };

    let artist = song
        .get("artists")
        .and_then(Value::as_array)
        .and_then(|arr| arr.first())
        .and_then(|a| a.get("name"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    Ok(StreamData {
        song_name: song
            .get("name")
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string(),
        artist,
        album: album
            .get("name")
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string(),
        duration: read_song_duration_ms(&song),
        img: album
            .get("picUrl")
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string(),
        mp3,
    })
}

fn read_song_duration_ms(song: &Value) -> i64 {
    song.get("duration")
        .and_then(Value::as_i64)
        .or_else(|| song.get("dt").and_then(Value::as_i64))
        .unwrap_or(0)
}

fn resolve_outer_url(id: &str, client: &Client) -> Result<String, String> {
    let url = format!("{MUSIC_BASE}/song/media/outer/url?id={id}.mp3");
    match client.get(&url).send() {
        Ok(resp) => {
            let status = resp.status();
            if status.is_success() {
                eprintln!("local_api outer url fallback ok song {id}");
                Ok(url)
            } else {
                Err(format!("outer url status {}", status.as_u16()))
            }
        }
        Err(err) => Err(format!("outer url request error: {}", err)),
    }
}

fn resolve_stream_data_legacy_dfs(
    id: &str,
    quality: &str,
    client: &Client,
) -> Result<String, String> {
    let song = get_song_detail_raw(id, client)?;
    let album = song.get("album").cloned().unwrap_or(Value::Null);
    let album_id = album
        .get("id")
        .and_then(Value::as_i64)
        .ok_or_else(|| "missing album id".to_string())?;
    let album_data_raw = music_get(client, &format!("/api/album/{album_id}"))?;
    let album_data: Value = serde_json::from_str(&album_data_raw).map_err(|e| e.to_string())?;
    let songs = album_data
        .get("album")
        .and_then(|a| a.get("songs"))
        .and_then(Value::as_array)
        .ok_or_else(|| "album songs not found".to_string())?;

    let sid = id.parse::<i64>().unwrap_or(0);
    let song_in_album = songs
        .iter()
        .find(|s| s.get("id").and_then(Value::as_i64).unwrap_or(0) == sid)
        .ok_or_else(|| "song not found in album".to_string())?;

    let quality_candidates = quality_field_candidates(quality);
    let mut dfs_id: Option<i64> = None;
    for field in quality_candidates {
        if let Some(v) = song_in_album
            .get(field)
            .and_then(|q| q.get("dfsId"))
            .and_then(Value::as_i64)
        {
            if v > 0 {
                dfs_id = Some(v);
                break;
            }
        }
    }
    if dfs_id.is_none() {
        for field in ["hMusic", "mMusic", "lMusic", "bMusic"] {
            if let Some(v) = song_in_album
                .get(field)
                .and_then(|q| q.get("dfsId"))
                .and_then(Value::as_i64)
            {
                if v > 0 {
                    dfs_id = Some(v);
                    break;
                }
            }
        }
    }
    let dfs_id = dfs_id.ok_or_else(|| "no available dfsId".to_string())?;
    let encrypted = decrypt_id(&dfs_id.to_string());
    Ok(format!("{MEDIA_BASE}{encrypted}/{dfs_id}.mp3"))
}

fn resolve_play_url_weapi(id: &str, quality: &str, client: &Client) -> Result<String, String> {
    let br_kbps = to_quality_kbps(quality);
    let body = json!({
        "ids": [id],
        "br": br_kbps * 1000,
        "encodeType": "mp3"
    });
    let payload = body.to_string();
    let first = aes_128_cbc_base64(&payload, WEAPI_NONCE, WEAPI_IV)?;
    let params = aes_128_cbc_base64(&first, WEAPI_SKEY, WEAPI_IV)?;
    let form = [
        ("params", params),
        ("encSecKey", WEAPI_ENCSEC_KEY.to_string()),
    ];
    let endpoints = [
        format!("{MUSIC_BASE}/api/song/enhance/player/url"),
        format!("{MUSIC_BASE}/weapi/song/enhance/player/url"),
    ];
    let mut last_err = String::new();
    for endpoint in endpoints {
        let req = default_headers(client.post(endpoint.clone())).form(&form);
        let raw = match req.send() {
            Ok(resp) => match resp.text() {
                Ok(t) => t,
                Err(err) => {
                    last_err = format!("{} read error: {}", endpoint, err);
                    continue;
                }
            },
            Err(err) => {
                last_err = format!("{} request error: {}", endpoint, err);
                continue;
            }
        };
        let data: Value = match parse_json_loose(&raw) {
            Ok(v) => v,
            Err(err) => {
                last_err = format!("{} json error: {}", endpoint, err);
                continue;
            }
        };
        let maybe_url = data
            .get("data")
            .and_then(Value::as_array)
            .and_then(|arr| arr.first())
            .and_then(|item| {
                item.get("url")
                    .and_then(Value::as_str)
                    .map(str::to_string)
                    .or_else(|| {
                        item.get("uf")
                            .and_then(|uf| uf.get("url"))
                            .and_then(Value::as_str)
                            .map(str::to_string)
                    })
            })
            .unwrap_or_default();
        if !maybe_url.is_empty() {
            eprintln!(
                "local_api weapi ok q={} br={} url={}",
                quality, br_kbps, maybe_url
            );
            return Ok(maybe_url);
        }
        last_err = format!("{} empty url response: {}", endpoint, raw);
    }
    match resolve_play_url_plain_api(id, br_kbps, client) {
        Ok(url) => Ok(url),
        Err(err) => Err(format!("{}; plain api failed: {}", last_err, err)),
    }
}

fn resolve_play_url_plain_api(id: &str, br_kbps: i32, client: &Client) -> Result<String, String> {
    let path = format!(
        "/api/song/enhance/player/url?ids=[{}]&br={}",
        id,
        br_kbps * 1000
    );
    let raw = music_get(client, &path)?;
    let data = parse_json_loose(&raw)?;
    let url = data
        .get("data")
        .and_then(Value::as_array)
        .and_then(|arr| arr.first())
        .and_then(|item| item.get("url").and_then(Value::as_str))
        .unwrap_or("")
        .to_string();
    if url.is_empty() {
        return Err(format!("empty plain api url response: {}", raw));
    }
    eprintln!("local_api plain api ok br={} url={}", br_kbps, url);
    Ok(url)
}

fn get_song_detail_raw(id: &str, client: &Client) -> Result<Value, String> {
    let raw = music_get(client, &format!("/api/song/detail?ids=[{id}]"))?;
    let data: Value = serde_json::from_str(&raw).map_err(|e| e.to_string())?;
    data.get("songs")
        .and_then(Value::as_array)
        .and_then(|arr| arr.first())
        .cloned()
        .ok_or_else(|| "song detail missing".to_string())
}

fn quality_field_candidates(quality: &str) -> Vec<&'static str> {
    match quality {
        "hMusic" => vec!["hMusic", "mMusic", "lMusic", "bMusic"],
        "mMusic" => vec!["mMusic", "hMusic", "lMusic", "bMusic"],
        "lMusic" => vec!["lMusic", "mMusic", "hMusic", "bMusic"],
        "bMusic" => vec!["bMusic", "lMusic", "mMusic", "hMusic"],
        _ => {
            let br = to_quality_kbps(quality);
            if br >= 320 {
                vec!["hMusic", "mMusic", "lMusic", "bMusic"]
            } else if br >= 160 {
                vec!["mMusic", "hMusic", "lMusic", "bMusic"]
            } else {
                vec!["lMusic", "mMusic", "hMusic", "bMusic"]
            }
        }
    }
}

fn to_quality_kbps(quality: &str) -> i32 {
    match quality {
        "hMusic" => 320,
        "mMusic" => 192,
        "lMusic" => 128,
        "bMusic" => 96,
        _ => {
            let parsed = quality.parse::<i32>().unwrap_or(128000);
            if parsed >= 1000 {
                parsed / 1000
            } else {
                parsed
            }
        }
    }
}

fn decrypt_id(id: &str) -> String {
    let magic = b"3go8&$8*3*3h0k(2)2";
    let mut bytes = id.as_bytes().to_vec();
    for (idx, b) in bytes.iter_mut().enumerate() {
        *b ^= magic[idx % magic.len()];
    }
    let digest = md5::compute(bytes);
    let encoded = base64::engine::general_purpose::STANDARD.encode(digest.0);
    encoded.replace('/', "_").replace('+', "-")
}

fn aes_128_cbc_base64(plain: &str, key: &str, iv: &str) -> Result<String, String> {
    let cipher = Encryptor::<Aes128>::new_from_slices(key.as_bytes(), iv.as_bytes())
        .map_err(|e| e.to_string())?;
    let mut buf = plain.as_bytes().to_vec();
    let msg_len = buf.len();
    let pad = 16 - (msg_len % 16);
    for _ in 0..pad {
        buf.push(0);
    }
    let out = cipher
        .encrypt_padded_mut::<Pkcs7>(&mut buf, msg_len)
        .map_err(|e| e.to_string())?;
    Ok(base64::engine::general_purpose::STANDARD.encode(out))
}

fn parse_json_loose(raw: &str) -> Result<Value, String> {
    if let Ok(v) = serde_json::from_str::<Value>(raw) {
        return Ok(v);
    }
    let start = raw.find('{').or_else(|| raw.find('['));
    let end_obj = raw.rfind('}');
    let end_arr = raw.rfind(']');
    let end = match (end_obj, end_arr) {
        (Some(a), Some(b)) => Some(std::cmp::max(a, b)),
        (Some(a), None) => Some(a),
        (None, Some(b)) => Some(b),
        (None, None) => None,
    };
    match (start, end) {
        (Some(s), Some(e)) if e > s => {
            let sliced = &raw[s..=e];
            serde_json::from_str::<Value>(sliced).map_err(|e| e.to_string())
        }
        _ => Err("no json payload found".to_string()),
    }
}

fn json_response(status: StatusCode, value: Value) -> Response<std::io::Cursor<Vec<u8>>> {
    plain_json_response(status, value.to_string())
}

fn plain_json_response(status: StatusCode, body: String) -> Response<std::io::Cursor<Vec<u8>>> {
    let mut response = Response::from_string(body).with_status_code(status);
    if let Ok(h) = Header::from_bytes(b"Content-Type", b"application/json; charset=utf-8") {
        response = response.with_header(h);
    }
    response
}

fn redirect_response(url: &str) -> Response<std::io::Cursor<Vec<u8>>> {
    let mut response = Response::from_string("").with_status_code(StatusCode(302));
    if let Ok(h) = Header::from_bytes(b"Location", url.as_bytes()) {
        response = response.with_header(h);
    }
    response
}

// ── YouTube Music / InnerTube helpers ────────────────────────────────────────

/// Returns the standard InnerTube `context` body fragment.
fn innertube_context() -> Value {
    json!({
        "context": {
            "client": {
                "clientName": INNERTUBE_CLIENT_NAME,
                "clientVersion": INNERTUBE_CLIENT_VERSION,
                "gl": "US",
                "hl": "en"
            }
        }
    })
}

/// Makes a blocking POST to `{INNERTUBE_BASE}{endpoint}?key={INNERTUBE_API_KEY}`
/// with all required InnerTube headers. Returns parsed JSON or an error string.
fn innertube_post(endpoint: &str, body: Value, client: &Client) -> Result<Value, String> {
    let url = format!("{}{}?key={}", INNERTUBE_BASE, endpoint, INNERTUBE_API_KEY);
    let resp = client
        .post(&url)
        .header("Content-Type", "application/json")
        .header("X-Goog-Api-Format-Version", "1")
        .header("X-YouTube-Client-Name", INNERTUBE_CLIENT_ID)
        .header("X-YouTube-Client-Version", INNERTUBE_CLIENT_VERSION)
        .header("X-Origin", "https://music.youtube.com")
        .header("Referer", "https://music.youtube.com/")
        .header("User-Agent", INNERTUBE_USER_AGENT)
        .json(&body)
        .send()
        .map_err(|e| format!("innertube_http_error: {}", e))?;
    resp.json::<Value>()
        .map_err(|e| format!("innertube_json_error: {}", e))
}

/// Calls the InnerTube `player` endpoint and returns a `StreamData` with the
/// best audio stream URL and video metadata.
fn innertube_stream_url(video_id: &str, client: &Client) -> Result<StreamData, String> {
    let mut body = innertube_context();
    body["videoId"] = json!(video_id);

    let resp = innertube_post("player", body, client)?;

    // ── video metadata ────────────────────────────────────────────────────────
    let details = resp.get("videoDetails").unwrap_or(&Value::Null);

    let song_name = details
        .get("title")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    let artist = details
        .get("author")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    let duration_secs = details
        .get("lengthSeconds")
        .and_then(Value::as_str)
        .and_then(|s| s.parse::<i64>().ok())
        .unwrap_or(0);
    let duration = duration_secs * 1000; // convert to milliseconds

    let img = details
        .get("thumbnail")
        .and_then(|t| t.get("thumbnails"))
        .and_then(Value::as_array)
        .and_then(|arr| arr.last())
        .and_then(|t| t.get("url"))
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    // ── stream selection ──────────────────────────────────────────────────────
    let adaptive_formats = resp
        .get("streamingData")
        .and_then(|sd| sd.get("adaptiveFormats"))
        .and_then(Value::as_array)
        .ok_or_else(|| "no_stream".to_string())?;

    if adaptive_formats.is_empty() {
        return Err("no_stream".to_string());
    }

    // First try to find itag=140 (audio/mp4 AAC 128kbps) for best compatibility.
    // Fall back to the audio-only format with the highest bitrate.
    let audio_formats: Vec<&Value> = adaptive_formats
        .iter()
        .filter(|f| {
            f.get("mimeType")
                .and_then(Value::as_str)
                .map(|m| m.starts_with("audio/"))
                .unwrap_or(false)
        })
        .collect();

    if audio_formats.is_empty() {
        return Err("no_stream".to_string());
    }

    // Prefer itag 140
    let best = audio_formats
        .iter()
        .find(|f| f.get("itag").and_then(Value::as_i64).unwrap_or(0) == 140)
        .copied()
        .unwrap_or_else(|| {
            // Otherwise pick highest bitrate
            audio_formats
                .iter()
                .max_by_key(|f| f.get("bitrate").and_then(Value::as_i64).unwrap_or(0))
                .copied()
                .unwrap_or(audio_formats[0])
        });

    let mp3 = best
        .get("url")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    if mp3.is_empty() {
        return Err("no_stream".to_string());
    }

    Ok(StreamData {
        song_name,
        artist,
        album: String::new(), // not available in player response
        duration,
        img,
        mp3,
    })
}

/// Searches YouTube Music for songs matching `query`, returns a JSON array
/// of up to `limit` normalized song objects.
fn innertube_search(query: &str, limit: usize, client: &Client) -> Value {
    let mut body = innertube_context();
    body["query"] = json!(query);
    // FILTER_SONG param — restricts results to songs only
    body["params"] = json!("EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D");

    let resp = match innertube_post("search", body, client) {
        Ok(v) => v,
        Err(_) => return json!([]),
    };

    // Navigate to musicShelfRenderer → contents
    let contents = resp
        .get("contents")
        .and_then(|c| c.get("tabbedSearchResultsRenderer"))
        .and_then(|t| t.get("tabs"))
        .and_then(Value::as_array)
        .and_then(|tabs| tabs.first())
        .and_then(|tab| tab.get("tabRenderer"))
        .and_then(|tr| tr.get("content"))
        .and_then(|c| c.get("sectionListRenderer"))
        .and_then(|sl| sl.get("contents"))
        .and_then(Value::as_array);

    let shelf_contents = contents.and_then(|arr| {
        arr.iter().find_map(|section| {
            section
                .get("musicShelfRenderer")
                .and_then(|msr| msr.get("contents"))
                .and_then(Value::as_array)
        })
    });

    let items = match shelf_contents {
        Some(v) => v,
        None => return json!([]),
    };

    let mut songs: Vec<Value> = Vec::new();
    for item in items.iter().take(limit) {
        let renderer = match item.get("musicResponsiveListItemRenderer") {
            Some(r) => r,
            None => continue,
        };

        // Title from flexColumns[0] → runs[0].text
        let title = renderer
            .get("flexColumns")
            .and_then(Value::as_array)
            .and_then(|cols| cols.first())
            .and_then(|c| c.get("musicResponsiveListItemFlexColumnRenderer"))
            .and_then(|fc| fc.get("text"))
            .and_then(|t| t.get("runs"))
            .and_then(Value::as_array)
            .and_then(|runs| runs.first())
            .and_then(|r| r.get("text"))
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string();

        // Artist from flexColumns[1] → runs[0].text
        let artist_yt = renderer
            .get("flexColumns")
            .and_then(Value::as_array)
            .and_then(|cols| cols.get(1))
            .and_then(|c| c.get("musicResponsiveListItemFlexColumnRenderer"))
            .and_then(|fc| fc.get("text"))
            .and_then(|t| t.get("runs"))
            .and_then(Value::as_array)
            .and_then(|runs| runs.first())
            .and_then(|r| r.get("text"))
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string();

        // video ID from overlay → playButton → watchEndpoint
        let video_id = renderer
            .get("overlay")
            .and_then(|o| o.get("musicItemThumbnailOverlayRenderer"))
            .and_then(|o| o.get("content"))
            .and_then(|c| c.get("musicPlayButtonRenderer"))
            .and_then(|pb| pb.get("playNavigationEndpoint"))
            .and_then(|ne| ne.get("watchEndpoint"))
            .and_then(|we| we.get("videoId"))
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string();

        if video_id.is_empty() {
            continue;
        }

        // Thumbnail — last (largest) thumbnail
        let img_yt = renderer
            .get("thumbnail")
            .and_then(|t| t.get("musicThumbnailRenderer"))
            .and_then(|mtr| mtr.get("thumbnail"))
            .and_then(|t| t.get("thumbnails"))
            .and_then(Value::as_array)
            .and_then(|arr| arr.last())
            .and_then(|t| t.get("url"))
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string();

        songs.push(json!({
            "id": video_id,
            "title": title,
            "artist": artist_yt,
            "album": "",
            "img": img_yt,
            "duration": 0,
            "source": "youtube"
        }));
    }

    json!(songs)
}

// ── YouTube Music HTTP route handlers ────────────────────────────────────────

/// Returns true if `id` is a valid YouTube video ID: exactly 11 chars from [A-Za-z0-9_-].
fn is_valid_youtube_id(id: &str) -> bool {
    id.len() == 11
        && id
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-')
}

/// GET /play/youtube/{video_id}[/{quality}]
///
/// Fetches the CDN audio stream URL from InnerTube, then **pipes the CDN
/// response bytes directly back** to the caller through `tiny_http`.  The QML
/// MediaPlayer therefore only ever talks to `127.0.0.1:39876` — it never
/// receives or follows a redirect to a `googlevideo.com` CDN URL.
///
/// Supported pass-through headers (upstream → client):
///   • Content-Type   (typically `audio/mp4`)
///   • Content-Length (enables duration/seek in MediaPlayer)
///   • Accept-Ranges  (signals that byte-range requests are OK)
///
/// Honoured incoming headers from the client:
///   • Range  (forwarded to the CDN so seek-to-position works)
fn handle_play_youtube(
    path: &str,
    range_header: Option<&str>,
    client: &Client,
) -> Response<std::io::Cursor<Vec<u8>>> {
    // path: "/play/youtube/{video_id}" or "/play/youtube/{video_id}/{quality}"
    let stripped = path.trim_start_matches("/play/youtube/");
    let video_id = stripped.split('/').next().unwrap_or("").trim();

    if video_id.is_empty() {
        return json_response(StatusCode(400), json!({"error": "missing video_id"}));
    }
    if !is_valid_youtube_id(video_id) {
        return json_response(
            StatusCode(400),
            json!({"error": "invalid youtube video id"}),
        );
    }

    // 1. Resolve the CDN stream URL via InnerTube.
    let cdn_url = match innertube_stream_url(video_id, client) {
        Ok(data) => data.mp3,
        Err(err) => {
            eprintln!(
                "local_api /play/youtube innertube failed video_id={}: {}",
                video_id, err
            );
            return json_response(StatusCode(502), json!({"error": err}));
        }
    };

    // 2. Open an HTTP GET to the CDN URL, forwarding Range if present.
    let mut cdn_req = client.get(&cdn_url);
    if let Some(range) = range_header {
        cdn_req = cdn_req.header("Range", range);
    }
    let cdn_resp = match cdn_req.send() {
        Ok(r) => r,
        Err(err) => {
            eprintln!(
                "local_api /play/youtube cdn fetch failed video_id={}: {}",
                video_id, err
            );
            return json_response(StatusCode(502), json!({"error": err.to_string()}));
        }
    };

    // 3. Collect headers we want to pass through before consuming the body.
    let status_code = cdn_resp.status().as_u16();
    let content_type = cdn_resp
        .headers()
        .get("Content-Type")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("audio/mp4")
        .to_string();
    let content_length: Option<String> = cdn_resp
        .headers()
        .get("Content-Length")
        .and_then(|v| v.to_str().ok())
        .map(str::to_string);
    let accept_ranges: Option<String> = cdn_resp
        .headers()
        .get("Accept-Ranges")
        .and_then(|v| v.to_str().ok())
        .map(str::to_string);

    // 4. Read the CDN body into memory and pipe it back.
    let body_bytes = match cdn_resp.bytes() {
        Ok(b) => b.to_vec(),
        Err(err) => {
            eprintln!(
                "local_api /play/youtube cdn body read failed video_id={}: {}",
                video_id, err
            );
            return json_response(StatusCode(502), json!({"error": err.to_string()}));
        }
    };

    // 5. Build the tiny_http response.
    let http_status = StatusCode(status_code);
    let mut response = Response::from_data(body_bytes).with_status_code(http_status);

    if let Ok(h) = Header::from_bytes(b"Content-Type", content_type.as_bytes()) {
        response = response.with_header(h);
    }
    if let Some(cl) = content_length {
        if let Ok(h) = Header::from_bytes(b"Content-Length", cl.as_bytes()) {
            response = response.with_header(h);
        }
    }
    if let Some(ar) = accept_ranges {
        if let Ok(h) = Header::from_bytes(b"Accept-Ranges", ar.as_bytes()) {
            response = response.with_header(h);
        }
    }

    response
}

/// GET /url/youtube/{video_id}
/// Returns JSON `{"url": "http://127.0.0.1:39876/play/youtube/{id}", "img": "..."}`.
/// The `url` field always points to the local proxy endpoint — never to a CDN URL.
fn handle_url_youtube(path: &str, client: &Client) -> Response<std::io::Cursor<Vec<u8>>> {
    let video_id = path.trim_start_matches("/url/youtube/").trim();
    if video_id.is_empty() {
        return json_response(StatusCode(400), json!({"error": "missing video_id"}));
    }
    if !is_valid_youtube_id(video_id) {
        return json_response(
            StatusCode(400),
            json!({"error": "invalid youtube video id"}),
        );
    }
    match innertube_stream_url(video_id, client) {
        Ok(data) => {
            let proxy_url = format!("http://{}/play/youtube/{}", LISTEN_ADDR, video_id);
            json_response(StatusCode(200), json!({"url": proxy_url, "img": data.img}))
        }
        Err(err) => json_response(StatusCode(502), json!({"error": err})),
    }
}
