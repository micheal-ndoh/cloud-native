use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter, Layer};
use tracing_appender::non_blocking::WorkerGuard;
use std::io;

#[derive(Debug, Clone)]
pub struct LoggingConfig {
    pub level: String,
    pub format: LogFormat,
    pub output: LogOutput,
}

#[derive(Debug, Clone)]
pub enum LogFormat {
    Json,
    Pretty,
}

#[derive(Debug, Clone)]
pub enum LogOutput {
    Stdout,
    File { directory: String },
}

impl LoggingConfig {
    pub fn from_env() -> Self {
        let level = std::env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string());
        
        let format = match std::env::var("LOG_FORMAT").unwrap_or_else(|_| "pretty".to_string()).as_str() {
            "json" => LogFormat::Json,
            _ => LogFormat::Pretty,
        };

        let output = match std::env::var("LOG_OUTPUT") {
            Ok(path) if path != "stdout" => LogOutput::File { directory: path },
            _ => LogOutput::Stdout,
        };

        Self { level, format, output }
    }

    pub fn init(&self) -> Option<WorkerGuard> {
        let env_filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| EnvFilter::new(&self.level));

        match (&self.format, &self.output) {
            (LogFormat::Json, LogOutput::Stdout) => {
                tracing_subscriber::registry()
                    .with(
                        tracing_subscriber::fmt::layer()
                            .json()
                            .with_filter(env_filter)
                    )
                    .init();
                None
            },
            (LogFormat::Pretty, LogOutput::Stdout) => {
                tracing_subscriber::registry()
                    .with(
                        tracing_subscriber::fmt::layer()
                            .pretty()
                            .with_filter(env_filter)
                    )
                    .init();
                None
            },
            (LogFormat::Json, LogOutput::File { directory }) => {
                let file_appender = tracing_appender::rolling::daily(directory, "task-api.log");
                let (non_blocking, guard) = tracing_appender::non_blocking(file_appender);
                
                tracing_subscriber::registry()
                    .with(
                        tracing_subscriber::fmt::layer()
                            .json()
                            .with_writer(non_blocking)
                            .with_filter(env_filter.clone())
                    )
                    .with(
                        tracing_subscriber::fmt::layer()
                            .compact()
                            .with_writer(io::stdout)
                            .with_filter(EnvFilter::new("info"))
                    )
                    .init();
                Some(guard)
            },
            (LogFormat::Pretty, LogOutput::File { directory }) => {
                let file_appender = tracing_appender::rolling::daily(directory, "task-api.log");
                let (non_blocking, guard) = tracing_appender::non_blocking(file_appender);
                
                tracing_subscriber::registry()
                    .with(
                        tracing_subscriber::fmt::layer()
                            .with_writer(non_blocking)
                            .with_filter(env_filter.clone())
                    )
                    .with(
                        tracing_subscriber::fmt::layer()
                            .compact()
                            .with_writer(io::stdout)
                            .with_filter(EnvFilter::new("info"))
                    )
                    .init();
                Some(guard)
            },
        }
    }
}
