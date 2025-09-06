use axum::{
    extract::{MatchedPath, Request},
    middleware::Next,
    response::Response,
};
use std::time::Instant;
use tracing::{info, warn, error, debug};
use uuid::Uuid;

pub async fn logging_middleware(
    request: Request,
    next: Next,
) -> Response {
    let request_id = Uuid::new_v4();
    let start = Instant::now();
    
    let method = request.method().clone();
    let uri = request.uri().clone();
    let version = request.version();
    
    // Extract matched path if available (for route-based logging)
    let path = request
        .extensions()
        .get::<MatchedPath>()
        .map(|mp| mp.as_str().to_owned())
        .unwrap_or_else(|| uri.path().to_owned());

    // Log request headers (excluding sensitive ones)
    let headers: std::collections::HashMap<String, String> = request
        .headers()
        .iter()
        .filter_map(|(name, value)| {
            let name_str = name.as_str().to_lowercase();
            // Skip sensitive headers
            if name_str.contains("authorization") || name_str.contains("cookie") || name_str.contains("token") {
                None
            } else {
                value.to_str().ok().map(|v| (name.to_string(), v.to_string()))
            }
        })
        .collect();

    info!(
        request_id = %request_id,
        method = %method,
        uri = %uri,
        path = path,
        version = ?version,
        headers = ?headers,
        "HTTP request started"
    );

    let response = next.run(request).await;
    let duration = start.elapsed();
    let status = response.status();

    // Log based on status code level
    match status.as_u16() {
        200..=299 => {
            info!(
                request_id = %request_id,
                method = %method,
                uri = %uri,
                path = path,
                status = %status,
                duration_ms = duration.as_millis(),
                "HTTP request completed successfully"
            );
        },
        300..=399 => {
            info!(
                request_id = %request_id,
                method = %method,
                uri = %uri,
                path = path,
                status = %status,
                duration_ms = duration.as_millis(),
                "HTTP request redirected"
            );
        },
        400..=499 => {
            warn!(
                request_id = %request_id,
                method = %method,
                uri = %uri,
                path = path,
                status = %status,
                duration_ms = duration.as_millis(),
                "HTTP request client error"
            );
        },
        500..=599 => {
            error!(
                request_id = %request_id,
                method = %method,
                uri = %uri,
                path = path,
                status = %status,
                duration_ms = duration.as_millis(),
                "HTTP request server error"
            );
        },
        _ => {
            debug!(
                request_id = %request_id,
                method = %method,
                uri = %uri,
                path = path,
                status = %status,
                duration_ms = duration.as_millis(),
                "HTTP request completed"
            );
        }
    }

    response
}
